import 'dart:io';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/services/storage_service.dart';

class StorageServiceImpl implements StorageService {
  final Directory? baseDirectoryOverride;

  StorageServiceImpl({this.baseDirectoryOverride});

  Future<Directory> _getBaseDirectory() async {
    if (baseDirectoryOverride != null) {
      return baseDirectoryOverride!;
    }
    return await getApplicationSupportDirectory();
  }

  Future<Directory> _getSessionsRoot() async {
    final base = await _getBaseDirectory();
    final sessionsDir = Directory(p.join(base.path, 'sessions'));
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
    return sessionsDir;
  }

  @override
  Future<Directory> createSessionDirectory(String sessionId) async {
    final sessionsRoot = await _getSessionsRoot();
    final sessionDir = Directory(p.join(sessionsRoot.path, sessionId));
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }
    return sessionDir;
  }

  @override
  Future<void> clearSession(String sessionId) async {
    final sessionsRoot = await _getSessionsRoot();
    final sessionDir = Directory(p.join(sessionsRoot.path, sessionId));
    if (await sessionDir.exists()) {
      await sessionDir.delete(recursive: true);
    }
  }

  @override
  Future<void> cleanupOrphanedSessions({String? activeSessionId}) async {
    final sessionsRoot = await _getSessionsRoot();
    if (!await sessionsRoot.exists()) return;

    final entities = sessionsRoot.listSync();
    for (final entity in entities) {
      if (entity is Directory) {
        final dirName = p.basename(entity.path);
        if (activeSessionId == null || dirName != activeSessionId) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {
            // Ignore file-in-use errors during background cleanup
          }
        }
      }
    }
  }

  @override
  Future<void> finalizeSession(String sessionId) async {
    await clearSession(sessionId);
  }

  @override
  Future<bool> saveToGallery(String filePath) async {
    try {
      await Gal.putImage(filePath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
