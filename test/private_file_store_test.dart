import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_nagpur/core/services/private_file_store.dart';

void main() {
  group('PrivateFileStore', () {
    late Directory temporary;
    late DateTime now;
    late PrivateFileStore store;

    setUp(() async {
      temporary = await Directory.systemTemp.createTemp(
        'smart_nagpur_private_files_',
      );
      now = DateTime.utc(2026, 8, 17, 12);
      store = PrivateFileStore(
        temporaryDirectory: () async => temporary,
        now: () => now,
      );
    });

    tearDown(() async {
      if (await temporary.exists()) {
        await temporary.delete(recursive: true);
      }
    });

    test(
      'allocates sensitive files below the temporary managed root',
      () async {
        final path = await store.allocatePath(
          PrivateFileArea.complaintPhotos,
          r'folder\photo name.jpg',
        );

        final expectedRoot = _join(
          temporary.path,
          PrivateFileStore.rootFolderName,
        );
        expect(path, startsWith('$expectedRoot${Platform.pathSeparator}'));
        expect(path, contains('complaint_photos'));
        expect(path, endsWith('photo_name.jpg'));
      },
    );

    test('deletes only files inside known managed areas', () async {
      final managedPath = await store.allocatePath(
        PrivateFileArea.vendorDocuments,
        'permit.pdf',
      );
      final managed = await File(managedPath).writeAsString('private');
      final outside = await File(
        _join(temporary.path, 'outside.pdf'),
      ).writeAsString('keep');
      final lookalikeDirectory = Directory(
        _join(temporary.path, '${PrivateFileStore.rootFolderName}_lookalike'),
      );
      await lookalikeDirectory.create();
      final lookalike = await File(
        _join(lookalikeDirectory.path, 'permit.pdf'),
      ).writeAsString('keep');

      await store.deleteManagedFiles([
        managed.path,
        outside.path,
        lookalike.path,
      ]);

      expect(await managed.exists(), isFalse);
      expect(await outside.exists(), isTrue);
      expect(await lookalike.exists(), isTrue);
    });

    test('prunes expired files but keeps recent cache entries', () async {
      final expired = await File(
        await store.allocatePath(PrivateFileArea.remoteCache, 'old.jpg'),
      ).writeAsString('old');
      final recent = await File(
        await store.allocatePath(PrivateFileArea.remoteCache, 'recent.jpg'),
      ).writeAsString('recent');
      await expired.setLastModified(now.subtract(const Duration(hours: 25)));
      await recent.setLastModified(now.subtract(const Duration(hours: 23)));

      await store.pruneExpired();

      expect(await expired.exists(), isFalse);
      expect(await recent.exists(), isTrue);
    });

    test(
      'clearAll removes the private root without touching siblings',
      () async {
        final managed = await File(
          await store.allocatePath(PrivateFileArea.remoteCache, 'cached.pdf'),
        ).writeAsString('private');
        final outside = await File(
          _join(temporary.path, 'outside.txt'),
        ).writeAsString('keep');

        await store.clearAll();

        expect(await managed.exists(), isFalse);
        expect(await outside.exists(), isTrue);
      },
    );
  });
}

String _join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';
