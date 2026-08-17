import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'private_file_store.dart';

class PickedDocument {
  const PickedDocument({
    required this.path,
    required this.name,
    required this.size,
    this.extension,
  });

  final String path;
  final String name;
  final int size;
  final String? extension;
}

class DocumentPickerException implements Exception {
  const DocumentPickerException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract interface class DocumentPickerService {
  Future<List<PickedDocument>> pickDocuments({bool allowMultiple = false});
}

class DeviceDocumentPickerService implements DocumentPickerService {
  const DeviceDocumentPickerService({PrivateFileStore? privateFiles})
    : _privateFiles = privateFiles;

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  final PrivateFileStore? _privateFiles;

  @override
  Future<List<PickedDocument>> pickDocuments({
    bool allowMultiple = false,
  }) async {
    try {
      final List<PlatformFile> result;
      if (allowMultiple) {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
      } else {
        final selected = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        result = selected == null ? const [] : [selected];
      }
      if (result.isEmpty) return const [];

      final privateFiles = _privateFiles ?? PrivateFileStore();
      final documents = <PickedDocument>[];
      for (final selected in result) {
        final size = await selected.length();
        if (size > 10 * 1024 * 1024) {
          throw const DocumentPickerException(
            'Choose a document smaller than 10 MB.',
          );
        }
        final target = await privateFiles.allocatePath(
          PrivateFileArea.vendorDocuments,
          selected.name,
        );
        if (selected.path != null) {
          await File(selected.path!).copy(target);
        } else {
          await File(
            target,
          ).writeAsBytes(await selected.readAsBytes(), flush: true);
        }
        documents.add(
          PickedDocument(
            path: target,
            name: selected.name,
            size: size,
            extension: _extension(selected.name),
          ),
        );
      }
      return documents;
    } on DocumentPickerException {
      rethrow;
    } catch (error) {
      throw DocumentPickerException(
        'The document could not be selected or saved. Try another file.',
        error,
      );
    }
  }

  String? _extension(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 || index == name.length - 1
        ? null
        : name.substring(index + 1).toLowerCase();
  }
}
