import 'dart:convert';

import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [StorageService] backed by [SharedPreferences]; objects are stored as a
/// JSON list under a single key.
class SharedPreferencesStorageService implements StorageService {
  static const String _storageKey = 'storage_objects';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<StorageObject>> _readAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null) return <StorageObject>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => StorageObject.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _writeAll(List<StorageObject> objects) async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey,
      jsonEncode(objects.map((o) => o.toJson()).toList()),
    );
  }

  @override
  Future<void> save(StorageObject object) async {
    final objects = await _readAll();
    final index = objects.indexWhere((o) => o.id == object.id);
    if (index >= 0) {
      objects[index] = object;
    } else {
      objects.add(object);
    }
    await _writeAll(objects);
  }

  @override
  Future<List<StorageObject>> getAll() => _readAll();

  @override
  Future<void> saveAll(List<StorageObject> objects) => _writeAll(objects);

  @override
  Future<void> delete(String id) async {
    final objects = await _readAll();
    objects.removeWhere((o) => o.id == id);
    await _writeAll(objects);
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_storageKey);
  }
}
