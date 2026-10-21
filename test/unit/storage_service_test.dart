import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/services/storage_service_impl.dart';

void main() {
  late Directory tempBaseDir;
  late StorageServiceImpl storageService;

  setUp(() async {
    tempBaseDir = await Directory.systemTemp.createTemp('storage_test_');
    storageService = StorageServiceImpl(baseDirectoryOverride: tempBaseDir);
  });

  tearDown(() async {
    if (await tempBaseDir.exists()) {
      await tempBaseDir.delete(recursive: true);
    }
  });

  test('creates session dir and cleans up on clearSession', () async {
    final sessionDir = await storageService.createSessionDirectory('session_123');
    expect(await sessionDir.exists(), isTrue);

    final dummyFile = File('${sessionDir.path}/shot_1.jpg');
    await dummyFile.writeAsString('test');
    expect(await dummyFile.exists(), isTrue);

    await storageService.clearSession('session_123');
    expect(await sessionDir.exists(), isFalse);
  });

  test('cleanupOrphanedSessions deletes stale directories but keeps activeSessionId', () async {
    await storageService.createSessionDirectory('stale_1');
    await storageService.createSessionDirectory('stale_2');
    await storageService.cleanupOrphanedSessions(activeSessionId: 'stale_2');

    final dir1 = Directory('${tempBaseDir.path}/sessions/stale_1');
    final dir2 = Directory('${tempBaseDir.path}/sessions/stale_2');
    expect(await dir1.exists(), isFalse);
    expect(await dir2.exists(), isTrue);
  });

  test('finalizeSession purges raw captures', () async {
    final sessionDir = await storageService.createSessionDirectory('session_fin');
    final dummyFile = File('${sessionDir.path}/shot_1.jpg');
    await dummyFile.writeAsString('raw shot');
    expect(await dummyFile.exists(), isTrue);

    await storageService.finalizeSession('session_fin');
    expect(await sessionDir.exists(), isFalse);
  });
}
