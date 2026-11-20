import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/in_memory_storage_service.dart';
import 'package:camera_app/viewmodels/storage_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageViewModel', () {
    late StorageViewModel vm;
    late InMemoryStorageService storage;

    setUp(() async {
      storage = InMemoryStorageService();
      await storage.saveAll(const [
        StorageObject(id: '1', name: 'first', data: 'a'),
        StorageObject(id: '2', name: 'second', data: 'b'),
        StorageObject(id: '3', name: 'third', data: 'c'),
      ]);
      vm = StorageViewModel(storage: storage);
      await vm.refresh();
    });

    tearDown(() {
      vm.dispose();
    });

    test('loads objects newest first', () {
      expect(vm.objects.map((o) => o.id), ['3', '2', '1']);
      expect(vm.isLoading, isFalse);
    });

    test('toggleEditing flips edit mode and notifies', () {
      var notified = 0;
      vm.addListener(() => notified++);

      vm.toggleEditing();
      expect(vm.isEditing, isTrue);
      vm.toggleEditing();
      expect(vm.isEditing, isFalse);
      expect(notified, 2);
    });

    test('exitEditMode turns editing off only when active', () {
      vm.exitEditMode();
      expect(vm.isEditing, isFalse);

      vm.toggleEditing();
      expect(vm.isEditing, isTrue);
      vm.exitEditMode();
      expect(vm.isEditing, isFalse);
    });

    test('reorderItems reorders display list and persists', () async {
      // Display order is [3, 2, 1]. Move index 0 ('3') to index 2.
      await vm.reorderItems(0, 2);

      expect(vm.objects.map((o) => o.id), ['2', '1', '3']);

      final stored = await storage.getAll();
      expect(stored.map((o) => o.id), ['3', '1', '2']);
    });

    test('reorderItems ignores invalid indices', () async {
      await vm.reorderItems(-1, 0);
      await vm.reorderItems(0, 99);
      expect(vm.objects.map((o) => o.id), ['3', '2', '1']);
    });

    test('delete removes object and refreshes', () async {
      await vm.delete('2');
      expect(vm.objects.map((o) => o.id), ['3', '1']);
    });

    test('rename updates name and keeps data', () async {
      await vm.rename('2', '  renamed  ');

      final renamed = vm.objects.firstWhere((o) => o.id == '2');
      expect(renamed.name, 'renamed');
      expect(renamed.data, 'b');
      expect(
        (await storage.getAll()).firstWhere((o) => o.id == '2').name,
        'renamed',
      );
    });

    test('rename can change color scheme', () async {
      await vm.rename('2', 'card', color: 'teal');

      final updated = vm.objects.firstWhere((o) => o.id == '2');
      expect(updated.color, 'teal');
      expect(
        (await storage.getAll()).firstWhere((o) => o.id == '2').color,
        'teal',
      );
    });

    test('rename ignores empty names and unknown ids', () async {
      await vm.rename('2', '   ');
      await vm.rename('missing', 'x');

      expect(vm.objects.firstWhere((o) => o.id == '2').name, 'second');
    });
  });
}
