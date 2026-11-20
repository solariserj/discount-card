import 'package:camera_app/models/storage_object.dart';

/// Persists [StorageObject] items.
abstract class StorageService {
  Future<void> save(StorageObject object);

  Future<List<StorageObject>> getAll();

  /// Replaces the whole collection, preserving the given order.
  Future<void> saveAll(List<StorageObject> objects);

  Future<void> delete(String id);

  Future<void> clear();
}
