import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'private_file_store.dart';

class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.name,
    required this.source,
  });

  final String path;
  final String name;
  final ImageSource source;
}

class MediaPickerException implements Exception {
  const MediaPickerException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract interface class MediaPickerService {
  Future<PickedMedia?> takePhoto();

  Future<PickedMedia?> choosePhoto();

  Future<void> removeManagedMedia(String path);
}

class DeviceMediaPickerService implements MediaPickerService {
  DeviceMediaPickerService({
    ImagePicker? picker,
    PrivateFileStore? privateFiles,
  }) : _picker = picker ?? ImagePicker(),
       _privateFiles = privateFiles ?? PrivateFileStore();

  final ImagePicker _picker;
  final PrivateFileStore _privateFiles;

  @override
  Future<PickedMedia?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<PickedMedia?> choosePhoto() => _pick(ImageSource.gallery);

  Future<PickedMedia?> _pick(ImageSource source) async {
    try {
      final selected = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2048,
      );
      if (selected == null) return null;

      final savedPath = await _privateFiles.allocatePath(
        PrivateFileArea.complaintPhotos,
        selected.name,
      );
      await selected.saveTo(savedPath);
      return PickedMedia(
        path: savedPath,
        name: _fileName(savedPath),
        source: source,
      );
    } catch (error) {
      throw MediaPickerException(
        source == ImageSource.camera
            ? 'The camera could not provide a photo. Try the gallery instead.'
            : 'The selected image could not be saved. Try another image.',
        error,
      );
    }
  }

  @override
  Future<void> removeManagedMedia(String path) =>
      _privateFiles.deleteManagedFiles([path]);

  String _fileName(String path) =>
      path.split(Platform.pathSeparator).where((part) => part.isNotEmpty).last;
}
