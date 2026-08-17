import '../../domain/models/vendor.dart';

class RemoteFileReference {
  const RemoteFileReference({
    required this.bucket,
    required this.objectPath,
    required this.originalName,
    required this.contentType,
    required this.byteSize,
  });

  final String bucket;
  final String objectPath;
  final String originalName;
  final String contentType;
  final int byteSize;

  Map<String, Object?> toJson() => {
    'bucket': bucket,
    'objectPath': objectPath,
    'originalName': originalName,
    'contentType': contentType,
    'byteSize': byteSize,
  };

  factory RemoteFileReference.fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Remote file reference is missing "$key".');
      }
      return value;
    }

    final size = json['byteSize'];
    if (size is! int || size < 0) {
      throw const FormatException(
        'Remote file reference has an invalid "byteSize".',
      );
    }

    return RemoteFileReference(
      bucket: requiredString('bucket'),
      objectPath: requiredString('objectPath'),
      originalName: requiredString('originalName'),
      contentType: requiredString('contentType'),
      byteSize: size,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RemoteFileReference &&
            bucket == other.bucket &&
            objectPath == other.objectPath &&
            originalName == other.originalName &&
            contentType == other.contentType &&
            byteSize == other.byteSize;
  }

  @override
  int get hashCode =>
      Object.hash(bucket, objectPath, originalName, contentType, byteSize);
}

class RemoteFileGatewayException implements Exception {
  const RemoteFileGatewayException(
    this.message, {
    required this.code,
    this.cause,
  });

  final String message;
  final String code;
  final Object? cause;

  @override
  String toString() => message;
}

class RemoteFileAuthenticationException extends RemoteFileGatewayException {
  const RemoteFileAuthenticationException()
    : super(
        'Sign in before uploading or opening private files.',
        code: 'file_authentication_required',
      );
}

class RemoteFileValidationException extends RemoteFileGatewayException {
  const RemoteFileValidationException(super.message, {super.cause})
    : super(code: 'invalid_file');
}

class RemoteFileUploadException extends RemoteFileGatewayException {
  const RemoteFileUploadException({Object? cause})
    : super(
        'The file could not be uploaded. Please try again.',
        code: 'file_upload_failed',
        cause: cause,
      );
}

class RemoteFileDeleteException extends RemoteFileGatewayException {
  const RemoteFileDeleteException({Object? cause})
    : super(
        'The uploaded file could not be removed. Please try again.',
        code: 'file_delete_failed',
        cause: cause,
      );
}

class RemoteFileDownloadException extends RemoteFileGatewayException {
  const RemoteFileDownloadException({Object? cause})
    : super(
        'The private file could not be opened. Please try again.',
        code: 'file_download_failed',
        cause: cause,
      );
}

abstract interface class RemoteFileGateway {
  Future<List<RemoteFileReference>> uploadComplaintPhotos(
    Iterable<String> localPaths,
  );

  Future<List<RemoteFileReference>> uploadVendorDocuments(
    Iterable<VendorDocument> documents,
  );

  Future<void> deleteFiles(Iterable<RemoteFileReference> references);

  Future<String> downloadToCache(RemoteFileReference reference);

  Future<String> cacheUploadedLocalFile(
    RemoteFileReference reference,
    String localPath,
  );

  Future<void> deleteManagedLocalFiles(Iterable<String> localPaths);

  Future<void> clearLocalSensitiveFiles();
}
