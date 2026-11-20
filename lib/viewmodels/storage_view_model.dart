import 'package:flutter/foundation.dart';
import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/shared_preferences_storage_service.dart';
import 'package:camera_app/services/storage_service.dart';

/// Loads persisted [StorageObject]s for display on the home page.
class StorageViewModel extends ChangeNotifier {
  StorageViewModel({StorageService? storage})
    : _storage = storage ?? SharedPreferencesStorageService() {
    refresh();
  }

  final StorageService _storage;

  /// Saved objects, most recent first.
  List<StorageObject> objects = <StorageObject>[];
  bool isLoading = true;

  /// Whether the list is in edit mode (delete buttons and drag handles).
  bool isEditing = false;

  void toggleEditing() {
    isEditing = !isEditing;
    notifyListeners();
  }

  void exitEditMode() {
    if (!isEditing) return;
    isEditing = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    final all = await _storage.getAll();
    objects = all.reversed.toList();
    isLoading = false;
    notifyListeners();
  }

  /// Reorders the displayed list and persists the new order.
  /// [newIndex] is the position after removal, as provided by
  /// [ReorderableListView.onReorderItem].
  Future<void> reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= objects.length ||
        newIndex < 0 ||
        newIndex > objects.length - 1) {
      return;
    }
    final item = objects.removeAt(oldIndex);
    objects.insert(newIndex, item);
    notifyListeners();
    await _storage.saveAll(objects.reversed.toList());
  }

  /// Renames the object with [id] and optionally changes its color scheme;
  /// empty names are ignored.
  Future<void> rename(String id, String newName, {String? color}) async {
    final name = newName.trim();
    if (name.isEmpty) return;
    final index = objects.indexWhere((o) => o.id == id);
    if (index < 0) return;
    final current = objects[index];
    await _storage.save(
      current.copyWith(name: name, color: color ?? current.color),
    );
    await refresh();
  }

  Future<void> delete(String id) async {
    await _storage.delete(id);
    await refresh();
  }
}
