import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum PrivateFileArea {
  complaintPhotos('complaint_photos'),
  vendorDocuments('vendor_documents'),
  remoteCache('remote_cache');

  const PrivateFileArea(this.folderName);

  final String folderName;
}

/// Keeps short-lived sensitive files in the platform cache and limits deletion
/// to directories created and owned by this application.
class PrivateFileStore {
  PrivateFileStore({
    Future<Directory> Function()? temporaryDirectory,
    DateTime Function()? now,
    this.retention = const Duration(hours: 24),
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _now = now ?? DateTime.now;

  static const rootFolderName = 'smart_nagpur_private';

  final Future<Directory> Function() _temporaryDirectory;
  final DateTime Function() _now;
  final Duration retention;

  Future<Directory> ensureArea(PrivateFileArea area) async {
    final root = await _safeRoot(create: true);
    final directory = Directory(_join(root!.path, area.folderName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _validatedArea(root, directory);
  }

  Future<String> allocatePath(PrivateFileArea area, String originalName) async {
    await pruneExpired();
    final directory = await ensureArea(area);
    var safeName = originalName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (safeName.isEmpty || safeName == '.' || safeName == '..') {
      safeName = 'private_file';
    }
    if (safeName.length > 120) {
      safeName = safeName.substring(safeName.length - 120);
    }
    final uniqueName = '${_now().microsecondsSinceEpoch}_$safeName';
    return _join(directory.path, uniqueName);
  }

  Future<void> deleteManagedFiles(Iterable<String> paths) async {
    final root = await _safeRoot(create: false);
    if (root == null) return;
    final areas = await _existingValidatedAreas(root);

    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.file) continue;

      try {
        final resolved = await File(path).resolveSymbolicLinks();
        if (!areas.any((area) => _isWithin(resolved, area.path))) continue;
        await File(path).delete();
      } on FileSystemException {
        // Cleanup is best effort and must not turn a successful submission into
        // a failure. Expired files are retried on the next private-file access.
      }
    }
  }

  Future<void> pruneExpired() async {
    final root = await _safeRoot(create: false);
    if (root == null) return;
    final cutoff = _now().subtract(retention);

    for (final area in await _existingValidatedAreas(root)) {
      await for (final entity in area.list(followLinks: false)) {
        try {
          final type = await FileSystemEntity.type(
            entity.path,
            followLinks: false,
          );
          if (type == FileSystemEntityType.link) {
            await entity.delete();
            continue;
          }
          if (type != FileSystemEntityType.file) continue;
          final resolved = await File(entity.path).resolveSymbolicLinks();
          if (!_isWithin(resolved, area.path)) continue;
          final modified = await File(entity.path).lastModified();
          if (modified.isBefore(cutoff)) await File(entity.path).delete();
        } on FileSystemException {
          // Another process or the operating system may evict cache files while
          // they are being inspected. The next pass can retry remaining files.
        }
      }
    }
  }

  Future<void> clearAll() async {
    final root = await _safeRoot(create: false);
    if (root != null && await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<Directory?> _safeRoot({required bool create}) async {
    final temporary = await _temporaryDirectory();
    if (!await temporary.exists()) {
      if (!create) return null;
      await temporary.create(recursive: true);
    }
    final resolvedTemporary = Directory(await temporary.resolveSymbolicLinks());
    final root = Directory(_join(resolvedTemporary.path, rootFolderName));
    if (!await root.exists()) {
      if (!create) return null;
      await root.create();
    }
    final resolvedRoot = Directory(await root.resolveSymbolicLinks());
    if (!_isWithin(resolvedRoot.path, resolvedTemporary.path)) {
      throw FileSystemException(
        'Private file root escaped the application cache.',
        root.path,
      );
    }
    return resolvedRoot;
  }

  Future<Directory> _validatedArea(Directory root, Directory area) async {
    final resolved = Directory(await area.resolveSymbolicLinks());
    if (!_isWithin(resolved.path, root.path)) {
      throw FileSystemException(
        'Private file area escaped the managed root.',
        area.path,
      );
    }
    return resolved;
  }

  Future<List<Directory>> _existingValidatedAreas(Directory root) async {
    final result = <Directory>[];
    for (final area in PrivateFileArea.values) {
      final directory = Directory(_join(root.path, area.folderName));
      if (!await directory.exists()) continue;
      try {
        result.add(await _validatedArea(root, directory));
      } on FileSystemException {
        // Never follow an unexpected managed-area link outside the cache root.
      }
    }
    return result;
  }

  bool _isWithin(String candidate, String parent) {
    final normalizedCandidate = _normalized(candidate);
    final normalizedParent = _normalized(parent);
    return normalizedCandidate.startsWith(
      '$normalizedParent${Platform.pathSeparator}',
    );
  }

  String _normalized(String path) =>
      Platform.isWindows ? path.toLowerCase() : path;

  String _join(String parent, String child) =>
      '$parent${Platform.pathSeparator}$child';
}
