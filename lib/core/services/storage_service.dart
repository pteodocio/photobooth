import 'dart:io';

abstract class StorageService {
  Future<Directory> createSessionDirectory(String sessionId);
  Future<void> clearSession(String sessionId);
  Future<void> cleanupOrphanedSessions({String? activeSessionId});
  Future<void> finalizeSession(String sessionId);
  Future<bool> saveToGallery(String filePath);
}
