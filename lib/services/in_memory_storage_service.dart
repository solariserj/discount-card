import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/storage_service.dart';

/// In-memory [StorageService], useful for tests and as a fallback.
class InMemoryStorageService implements StorageService {
  final List<StorageObject> _objects = <StorageObject>[];

  @override
  Future<void> save(StorageObject object) async {
    final index = _objects.indexWhere((o) => o.id == object.id);
    if (index >= 0) {
      _objects[index] = object;
    } else {
      _objects.add(object);
    }
  }

  @override
  Future<List<StorageObject>> getAll() async =>
      List<StorageObject>.unmodifiable(_objects);

  @override
  Future<void> saveAll(List<StorageObject> objects) async {
    _objects
      ..clear()
      ..addAll(objects);
  }

  @override
  Future<void> delete(String id) async {
    _objects.removeWhere((o) => o.id == id);
  }

  @override
  Future<void> clear() async => _objects.clear();
}
