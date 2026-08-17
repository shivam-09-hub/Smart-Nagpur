import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/domain.dart';
import '../remote/remote_data_gateway.dart';
import '../remote/remote_file_gateway.dart';

class SupabaseRemoteDataGateway implements RemoteDataGateway {
  SupabaseRemoteDataGateway(this._client, this._files);

  final SupabaseClient _client;
  final RemoteFileGateway _files;

  @override
  Future<RemoteUserData> loadCurrentUserData() async {
    _requireUserId();
    final response = await _request<dynamic>(
      () => _client.rpc('get_current_user_data'),
    );
    final root = _map(response, 'get_current_user_data');

    final profileJson = root['profile'];
    if (profileJson == null) {
      throw const RemoteDataGatewayException(
        'Your profile could not be loaded. Sign out and try again.',
        code: 'profile_missing',
      );
    }
    final profile = UserProfile.fromJson(_map(profileJson, 'profile'));

    final complaints = <ComplaintRecord>[];
    for (final item in _list(root['complaints'], 'complaints')) {
      complaints.add(
        await _complaintFromRemote(item, downloadMissingFiles: true),
      );
    }
    final vendorApplications = <VendorApplication>[];
    for (final item in _list(
      root['vendorApplications'],
      'vendorApplications',
    )) {
      vendorApplications.add(
        await _vendorApplicationFromRemote(item, downloadMissingFiles: true),
      );
    }
    final notifications = _list(root['notifications'], 'notifications')
        .map((item) => AppNotification.fromJson(_map(item, 'notification')))
        .toList(growable: false);

    return RemoteUserData(
      profile: profile,
      complaints: complaints,
      vendorApplications: vendorApplications,
      notifications: notifications,
    );
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final userId = _requireUserId();
    final response = await _request<dynamic>(
      () => _client
          .from('profiles')
          .update({
            'name': profile.name.trim(),
            'phone': profile.phone.trim(),
            'address': profile.address.trim(),
          })
          .eq('id', userId)
          .select('id'),
    );
    if (response is! List || response.isEmpty) {
      throw const RemoteDataGatewayException(
        'Your profile could not be found. Sign out and try again.',
        code: 'profile_missing',
      );
    }
    return profile;
  }

  @override
  Future<ComplaintRecord> submitComplaint(ComplaintDraft draft) async {
    _requireUserId();
    final List<RemoteFileReference> uploaded;
    try {
      uploaded = await _files.uploadComplaintPhotos(draft.photoPaths);
    } on RemoteFileGatewayException catch (error) {
      throw RemoteDataGatewayException(
        error.message,
        code: error.code,
        cause: error,
      );
    }
    final payload = Map<String, Object?>.from(draft.toJson())
      ..remove('photoPaths');
    final attachments = <Map<String, Object?>>[];
    for (var index = 0; index < uploaded.length; index++) {
      final reference = uploaded[index];
      attachments.add({...reference.toJson(), 'sortOrder': index});
    }

    final dynamic response;
    try {
      response = await _request<dynamic>(
        () => _client.rpc(
          'submit_complaint',
          params: {'payload': payload, 'attachments': attachments},
        ),
      );
    } catch (error, stackTrace) {
      try {
        await _files.deleteFiles(uploaded);
      } catch (_) {
        // Preserve the original database failure; orphan cleanup can be retried.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    try {
      final cachedPathsByObject = await _cacheUploadedLocalFiles(
        uploaded,
        draft.photoPaths,
      );
      return await _complaintFromRemote(
        response,
        localPathsByObject: cachedPathsByObject,
      );
    } finally {
      await _bestEffortDeleteManagedLocalFiles(draft.photoPaths);
    }
  }

  @override
  Future<VendorApplication> submitVendorApplication(
    VendorApplicationDraft draft,
  ) async {
    _requireUserId();
    final List<RemoteFileReference> uploaded;
    try {
      uploaded = await _files.uploadVendorDocuments(draft.documents);
    } on RemoteFileGatewayException catch (error) {
      throw RemoteDataGatewayException(
        error.message,
        code: error.code,
        cause: error,
      );
    }
    final payload = Map<String, Object?>.from(draft.toJson())
      ..remove('documents');
    final documents = <Map<String, Object?>>[];
    for (var index = 0; index < uploaded.length; index++) {
      final reference = uploaded[index];
      final document = draft.documents[index];
      documents.add({
        ...reference.toJson(),
        'sortOrder': index,
        'type': document.type,
        'label': document.label,
        'requirement': document.requirement.name,
      });
    }

    final dynamic response;
    try {
      response = await _request<dynamic>(
        () => _client.rpc(
          'submit_vendor_application',
          params: {'payload': payload, 'documents': documents},
        ),
      );
    } catch (error, stackTrace) {
      try {
        await _files.deleteFiles(uploaded);
      } catch (_) {
        // Preserve the original database failure; orphan cleanup can be retried.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    try {
      final cachedPathsByObject = await _cacheUploadedLocalFiles(
        uploaded,
        draft.documents.map((document) => document.path).toList(),
      );
      return await _vendorApplicationFromRemote(
        response,
        localPathsByObject: cachedPathsByObject,
      );
    } finally {
      await _bestEffortDeleteManagedLocalFiles(
        draft.documents.map((document) => document.path),
      );
    }
  }

  @override
  Future<void> markNotificationRead(String id) async {
    final userId = _requireUserId();
    await _request<dynamic>(
      () => _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('owner_id', userId),
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    final userId = _requireUserId();
    await _request<dynamic>(
      () => _client
          .from('notifications')
          .update({'is_read': true})
          .eq('owner_id', userId)
          .eq('is_read', false),
    );
  }

  Future<ComplaintRecord> _complaintFromRemote(
    Object? value, {
    Map<String, String> localPathsByObject = const {},
    bool downloadMissingFiles = false,
  }) async {
    final json = Map<String, Object?>.from(_map(value, 'complaint'));
    final photos = _list(json.remove('photos'), 'complaint.photos');
    final photoPaths = <String>[];
    for (final item in photos) {
      final reference = RemoteFileReference.fromJson(
        _map(item, 'complaint photo'),
      );
      photoPaths.add(
        localPathsByObject[reference.objectPath] ??
            (downloadMissingFiles ? await _downloadToCache(reference) : ''),
      );
    }
    json['photoPaths'] = photoPaths;
    _validateComplaint(json);
    return ComplaintRecord.fromJson(json);
  }

  Future<VendorApplication> _vendorApplicationFromRemote(
    Object? value, {
    Map<String, String> localPathsByObject = const {},
    bool downloadMissingFiles = false,
  }) async {
    final json = Map<String, Object?>.from(_map(value, 'vendor application'));
    final details = Map<String, Object?>.from(
      _map(json['details'], 'vendor application details'),
    );
    final remoteDocuments = _list(
      details.remove('documents'),
      'vendor application documents',
    );
    final localDocuments = <Map<String, Object?>>[];
    for (final item in remoteDocuments) {
      final remote = _map(item, 'vendor document');
      final reference = RemoteFileReference.fromJson(remote);
      localDocuments.add({
        'type': remote['type'] as String? ?? '',
        'label': remote['label'] as String? ?? '',
        'requirement': remote['requirement'] as String? ?? 'optional',
        'path':
            localPathsByObject[reference.objectPath] ??
            (downloadMissingFiles ? await _downloadToCache(reference) : ''),
      });
    }
    details['documents'] = localDocuments;
    json['details'] = details;
    _validateVendorApplication(json);
    return VendorApplication.fromJson(json);
  }

  void _validateComplaint(Map<String, Object?> json) {
    _requiredString(json, 'id');
    _requiredString(json, 'issue');
    _requiredString(json, 'description');
    _requiredDate(json, 'createdAt');
    _requiredDate(json, 'updatedAt');
    final service = _requiredString(json, 'serviceType');
    if (!ServiceType.values.any((value) => value.name == service)) {
      throw const RemoteDataGatewayException(
        'The service returned an unknown complaint service type.',
        code: 'invalid_remote_data',
      );
    }
    final status = _requiredString(json, 'status');
    if (!ComplaintStatus.values.any((value) => value.name == status)) {
      throw const RemoteDataGatewayException(
        'The service returned an unknown complaint status.',
        code: 'invalid_remote_data',
      );
    }
  }

  void _validateVendorApplication(Map<String, Object?> json) {
    _requiredString(json, 'id');
    _requiredDate(json, 'createdAt');
    _requiredDate(json, 'updatedAt');
    final status = _requiredString(json, 'status');
    if (!VendorStatus.values.any((value) => value.name == status)) {
      throw const RemoteDataGatewayException(
        'The service returned an unknown vendor status.',
        code: 'invalid_remote_data',
      );
    }
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw RemoteDataGatewayException(
        'The service returned invalid data for $key.',
        code: 'invalid_remote_data',
      );
    }
    return value;
  }

  void _requiredDate(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || DateTime.tryParse(value) == null) {
      throw RemoteDataGatewayException(
        'The service returned an invalid timestamp for $key.',
        code: 'invalid_remote_data',
      );
    }
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const RemoteDataGatewayException(
        'Sign in before accessing your civic requests.',
        code: 'authentication_required',
      );
    }
    return userId;
  }

  Future<String> _downloadToCache(RemoteFileReference reference) async {
    try {
      return await _files.downloadToCache(reference);
    } on RemoteFileDownloadException {
      // One unavailable attachment must not prevent the account from loading.
      return '';
    } on RemoteFileGatewayException catch (error) {
      throw RemoteDataGatewayException(
        error.message,
        code: error.code,
        cause: error,
      );
    }
  }

  Future<Map<String, String>> _cacheUploadedLocalFiles(
    List<RemoteFileReference> references,
    List<String> localPaths,
  ) async {
    final result = <String, String>{};
    for (var index = 0; index < references.length; index++) {
      final reference = references[index];
      try {
        result[reference.objectPath] = await _files.cacheUploadedLocalFile(
          reference,
          localPaths[index],
        );
      } catch (_) {
        // The database write has succeeded. Mark only this file unavailable.
        result[reference.objectPath] = '';
      }
    }
    return result;
  }

  Future<void> _bestEffortDeleteManagedLocalFiles(
    Iterable<String> paths,
  ) async {
    try {
      await _files.deleteManagedLocalFiles(paths);
    } catch (_) {
      // The cloud write already succeeded. Stale cache files are pruned later.
    }
  }

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 25));
    } on TimeoutException catch (error) {
      throw RemoteGatewayUnavailableException(cause: error);
    } on SocketException catch (error) {
      throw RemoteGatewayUnavailableException(cause: error);
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202' || error.code == '42P01') {
        throw RemoteDataGatewayException(
          'Supabase is connected, but the Smart Nagpur schema is not installed.',
          code: 'schema_not_installed',
          cause: error,
        );
      }
      throw RemoteDataGatewayException(
        error.message.isEmpty
            ? 'The online service rejected the request.'
            : error.message,
        code: error.code,
        cause: error,
      );
    } on RemoteDataGatewayException {
      rethrow;
    } catch (error) {
      final lower = error.toString().toLowerCase();
      if (lower.contains('socket') ||
          lower.contains('network') ||
          lower.contains('connection')) {
        throw RemoteGatewayUnavailableException(cause: error);
      }
      throw RemoteDataGatewayException(
        'The online service could not complete the request.',
        cause: error,
      );
    }
  }

  Map<String, Object?> _map(Object? value, String label) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw RemoteDataGatewayException(
      'The service returned invalid $label data.',
      code: 'invalid_remote_data',
    );
  }

  List<Object?> _list(Object? value, String label) {
    if (value == null) return const [];
    if (value is List) return List<Object?>.from(value);
    throw RemoteDataGatewayException(
      'The service returned invalid $label data.',
      code: 'invalid_remote_data',
    );
  }
}
