import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/private_file_store.dart';
import '../../domain/models/vendor.dart';
import '../remote/remote_file_gateway.dart';

class SupabaseFileGateway implements RemoteFileGateway {
  SupabaseFileGateway(
    this._client, {
    Uuid? uuid,
    PrivateFileStore? privateFiles,
  }) : _uuid = uuid ?? const Uuid(),
       _privateFiles = privateFiles ?? PrivateFileStore();

  static const complaintPhotosBucket = 'complaint-photos';
  static const vendorDocumentsBucket = 'vendor-documents';
  static const maxComplaintPhotoBytes = 10 * 1024 * 1024;
  static const maxVendorDocumentBytes = 10 * 1024 * 1024;

  static const _complaintTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };
  static const _vendorTypes = <String, String>{
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
  };
  static const _privateBuckets = {complaintPhotosBucket, vendorDocumentsBucket};

  final SupabaseClient _client;
  final Uuid _uuid;
  final PrivateFileStore _privateFiles;

  @override
  Future<List<RemoteFileReference>> uploadComplaintPhotos(
    Iterable<String> localPaths,
  ) async {
    final ownerUid = _authenticatedOwnerUid();
    final sources = <_ValidatedSource>[];
    for (final path in localPaths) {
      sources.add(
        await _validateSource(
          path,
          allowedTypes: _complaintTypes,
          maxBytes: maxComplaintPhotoBytes,
          kindLabel: 'photo',
        ),
      );
    }
    return _uploadGroup(
      ownerUid: ownerUid,
      bucket: complaintPhotosBucket,
      sources: sources,
    );
  }

  @override
  Future<List<RemoteFileReference>> uploadVendorDocuments(
    Iterable<VendorDocument> documents,
  ) async {
    final ownerUid = _authenticatedOwnerUid();
    final sources = <_ValidatedSource>[];
    for (final document in documents) {
      sources.add(
        await _validateSource(
          document.path,
          allowedTypes: _vendorTypes,
          maxBytes: maxVendorDocumentBytes,
          kindLabel: 'document',
        ),
      );
    }
    return _uploadGroup(
      ownerUid: ownerUid,
      bucket: vendorDocumentsBucket,
      sources: sources,
    );
  }

  @override
  Future<void> deleteFiles(Iterable<RemoteFileReference> references) async {
    final ownerUid = _authenticatedOwnerUid();
    final files = references.toList(growable: false);
    for (final reference in files) {
      _validateReference(reference, ownerUid);
    }

    try {
      await _remove(files);
    } catch (error) {
      throw RemoteFileDeleteException(cause: error);
    }
  }

  @override
  Future<String> downloadToCache(RemoteFileReference reference) async {
    final ownerUid = _authenticatedOwnerUid();
    _validateReference(reference, ownerUid);

    try {
      await _privateFiles.pruneExpired();
      final target = await _cacheTarget(reference);

      if (await target.exists() &&
          await target.length() == reference.byteSize &&
          await _fileMatchesType(target, reference.contentType)) {
        return target.path;
      }

      final bytes = await _client.storage
          .from(reference.bucket)
          .download(reference.objectPath)
          .timeout(const Duration(seconds: 15));
      if (bytes.length != reference.byteSize ||
          !_bytesMatchType(bytes, reference.contentType)) {
        throw const FormatException(
          'The downloaded file does not match its stored metadata.',
        );
      }

      final partial = File('${target.path}.part-${_uuid.v4()}');
      try {
        await partial.writeAsBytes(bytes, flush: true);
        if (await target.exists()) await target.delete();
        await partial.rename(target.path);
      } finally {
        if (await partial.exists()) await partial.delete();
      }
      return target.path;
    } on RemoteFileGatewayException {
      rethrow;
    } catch (error) {
      throw RemoteFileDownloadException(cause: error);
    }
  }

  @override
  Future<String> cacheUploadedLocalFile(
    RemoteFileReference reference,
    String localPath,
  ) async {
    final ownerUid = _authenticatedOwnerUid();
    _validateReference(reference, ownerUid);

    try {
      final allowedTypes = reference.bucket == complaintPhotosBucket
          ? _complaintTypes
          : _vendorTypes;
      final maxBytes = reference.bucket == complaintPhotosBucket
          ? maxComplaintPhotoBytes
          : maxVendorDocumentBytes;
      final source = await _validateSource(
        localPath,
        allowedTypes: allowedTypes,
        maxBytes: maxBytes,
        kindLabel: reference.bucket == complaintPhotosBucket
            ? 'photo'
            : 'document',
      );
      if (source.byteSize != reference.byteSize ||
          source.contentType != reference.contentType) {
        throw const FormatException(
          'The uploaded file does not match its stored metadata.',
        );
      }

      await _privateFiles.pruneExpired();
      final target = await _cacheTarget(reference);
      final partial = File('${target.path}.part-${_uuid.v4()}');
      try {
        await source.file.copy(partial.path);
        if (await partial.length() != reference.byteSize ||
            !await _fileMatchesType(partial, reference.contentType)) {
          throw const FormatException(
            'The cached file does not match its stored metadata.',
          );
        }
        if (await target.exists()) await target.delete();
        await partial.rename(target.path);
      } finally {
        if (await partial.exists()) await partial.delete();
      }
      return target.path;
    } on RemoteFileGatewayException {
      rethrow;
    } catch (error) {
      throw RemoteFileDownloadException(cause: error);
    }
  }

  @override
  Future<void> deleteManagedLocalFiles(Iterable<String> localPaths) =>
      _privateFiles.deleteManagedFiles(localPaths);

  @override
  Future<void> clearLocalSensitiveFiles() => _privateFiles.clearAll();

  Future<File> _cacheTarget(RemoteFileReference reference) async {
    final cacheDirectory = await _privateFiles.ensureArea(
      PrivateFileArea.remoteCache,
    );
    final cacheName = '${reference.bucket}_${reference.objectPath}'.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    return File('${cacheDirectory.path}${Platform.pathSeparator}$cacheName');
  }

  String _authenticatedOwnerUid() {
    final ownerUid = _client.auth.currentUser?.id.trim();
    if (ownerUid == null ||
        ownerUid.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(ownerUid)) {
      throw const RemoteFileAuthenticationException();
    }
    return ownerUid;
  }

  Future<_ValidatedSource> _validateSource(
    String path, {
    required Map<String, String> allowedTypes,
    required int maxBytes,
    required String kindLabel,
  }) async {
    if (path.trim().isEmpty) {
      throw RemoteFileValidationException('Choose a $kindLabel to upload.');
    }

    final file = File(path);
    try {
      if (!await file.exists()) {
        throw RemoteFileValidationException(
          'The selected $kindLabel is no longer available.',
        );
      }
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        throw RemoteFileValidationException(
          'The selected $kindLabel is not a file.',
        );
      }

      final originalName = _baseName(path);
      final extension = _extension(originalName);
      final contentType = allowedTypes[extension];
      if (contentType == null) {
        throw RemoteFileValidationException(
          'The selected $kindLabel type is not supported.',
        );
      }

      final byteSize = stat.size;
      if (byteSize <= 0) {
        throw RemoteFileValidationException(
          'The selected $kindLabel is empty.',
        );
      }
      if (byteSize > maxBytes) {
        final maxMegabytes = maxBytes ~/ (1024 * 1024);
        throw RemoteFileValidationException(
          'Choose a $kindLabel smaller than $maxMegabytes MB.',
        );
      }
      if (!await _fileMatchesType(file, contentType)) {
        throw RemoteFileValidationException(
          'The selected $kindLabel content does not match its file type.',
        );
      }

      return _ValidatedSource(
        file: file,
        originalName: originalName,
        extension: extension,
        contentType: contentType,
        byteSize: byteSize,
      );
    } on RemoteFileValidationException {
      rethrow;
    } on FileSystemException catch (error) {
      throw RemoteFileValidationException(
        'The selected $kindLabel could not be read.',
        cause: error,
      );
    }
  }

  Future<List<RemoteFileReference>> _uploadGroup({
    required String ownerUid,
    required String bucket,
    required List<_ValidatedSource> sources,
  }) async {
    if (sources.isEmpty) return const [];

    final groupUuid = _uuid.v4();
    final tasks = sources
        .map((source) {
          final objectPath =
              '$ownerUid/$groupUuid/${_uuid.v4()}.${source.extension}';
          return _UploadTask(
            source: source,
            reference: RemoteFileReference(
              bucket: bucket,
              objectPath: objectPath,
              originalName: source.originalName,
              contentType: source.contentType,
              byteSize: source.byteSize,
            ),
          );
        })
        .toList(growable: false);
    final attempted = <RemoteFileReference>[];

    try {
      for (final task in tasks) {
        attempted.add(task.reference);
        await _client.storage
            .from(bucket)
            .upload(
              task.reference.objectPath,
              task.source.file,
              fileOptions: FileOptions(
                upsert: false,
                contentType: task.reference.contentType,
              ),
            );
      }
      return tasks.map((task) => task.reference).toList(growable: false);
    } catch (error) {
      await _bestEffortRemove(attempted);
      throw RemoteFileUploadException(cause: error);
    }
  }

  void _validateReference(RemoteFileReference reference, String ownerUid) {
    final pathSegments = reference.objectPath.split('/');
    if (!_privateBuckets.contains(reference.bucket) ||
        !reference.objectPath.startsWith('$ownerUid/') ||
        reference.objectPath.contains('\\') ||
        pathSegments.length != 3 ||
        pathSegments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw const RemoteFileValidationException(
        'The private file reference is invalid for this account.',
      );
    }

    final allowedTypes = reference.bucket == complaintPhotosBucket
        ? _complaintTypes
        : _vendorTypes;
    final maxBytes = reference.bucket == complaintPhotosBucket
        ? maxComplaintPhotoBytes
        : maxVendorDocumentBytes;
    final extension = _extension(_baseName(reference.objectPath));
    if (allowedTypes[extension] != reference.contentType ||
        reference.byteSize <= 0 ||
        reference.byteSize > maxBytes ||
        reference.originalName.trim().isEmpty) {
      throw const RemoteFileValidationException(
        'The private file metadata is invalid.',
      );
    }
  }

  Future<void> _bestEffortRemove(
    Iterable<RemoteFileReference> references,
  ) async {
    try {
      await _remove(references);
    } catch (_) {
      // Preserve the upload failure; a later authenticated cleanup can retry.
    }
  }

  Future<void> _remove(Iterable<RemoteFileReference> references) async {
    final byBucket = <String, List<String>>{};
    for (final reference in references) {
      byBucket
          .putIfAbsent(reference.bucket, () => <String>[])
          .add(reference.objectPath);
    }
    for (final entry in byBucket.entries) {
      if (entry.value.isEmpty) continue;
      await _client.storage.from(entry.key).remove(entry.value);
    }
  }

  Future<bool> _fileMatchesType(File file, String contentType) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final header = await handle.read(16);
      return _bytesMatchType(header, contentType);
    } finally {
      await handle?.close();
    }
  }

  bool _bytesMatchType(Uint8List bytes, String contentType) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    return switch (contentType) {
      'image/jpeg' => startsWith(const [0xff, 0xd8, 0xff]),
      'image/png' => startsWith(const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]),
      'image/webp' =>
        bytes.length >= 12 &&
            startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50,
      'application/pdf' => startsWith(const [0x25, 0x50, 0x44, 0x46, 0x2d]),
      _ => false,
    };
  }

  String _baseName(String path) =>
      path.split(RegExp(r'[/\\]')).where((segment) => segment.isNotEmpty).last;

  String _extension(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 || index == name.length - 1
        ? ''
        : name.substring(index + 1).toLowerCase();
  }
}

class _ValidatedSource {
  const _ValidatedSource({
    required this.file,
    required this.originalName,
    required this.extension,
    required this.contentType,
    required this.byteSize,
  });

  final File file;
  final String originalName;
  final String extension;
  final String contentType;
  final int byteSize;
}

class _UploadTask {
  const _UploadTask({required this.source, required this.reference});

  final _ValidatedSource source;
  final RemoteFileReference reference;
}
