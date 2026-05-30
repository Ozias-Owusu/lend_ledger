import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a local profile photo per signed-in user (no upload API yet).
class ProfileImageStorage {
  ProfileImageStorage._();

  static const _pathKey = 'local_profile_image_path';
  static const _userKey = 'local_profile_image_user_id';

  static Future<String?> getPathForUser(String userId) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getString(_userKey) != userId) return null;
    final path = sp.getString(_pathKey);
    if (path == null || path.isEmpty) return null;
    if (!File(path).existsSync()) return null;
    return path;
  }

  static Future<String> saveForUser(String userId, String sourcePath) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw StateError('Profile image file not found.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final dest = File(p.join(dir.path, 'profile_$userId$safeExt'));

    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(dest.path);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_pathKey, dest.path);
    await sp.setString(_userKey, userId);
    return dest.path;
  }

  static Future<void> clearForUser(String userId) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getString(_userKey) != userId) return;
    final path = sp.getString(_pathKey);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await sp.remove(_pathKey);
    await sp.remove(_userKey);
  }
}
