import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/in_memory_storage_service.dart';
import 'package:camera_app/services/shared_preferences_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InMemoryStorageService', () {
    late InMemoryStorageService service;

    setUp(() {
      service = InMemoryStorageService();
    });

    test('saves and returns all objects', () async {
      await service.save(
        const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
      );
      await service.save(
        const StorageObject(id: '2', name: 'ean13', data: '123'),
      );

      final all = await service.getAll();
      expect(all, hasLength(2));
      expect(all[0].data, 'abc');
      expect(all[1].data, '123');
    });

    test('save with same id overwrites', () async {
      await service.save(const StorageObject(id: '1', name: 'a', data: 'old'));
      await service.save(const StorageObject(id: '1', name: 'b', data: 'new'));

      final all = await service.getAll();
      expect(all, hasLength(1));
      expect(all.single.data, 'new');
    });

    test('delete removes by id', () async {
      await service.save(const StorageObject(id: '1', name: 'a', data: 'x'));
      await service.save(const StorageObject(id: '2', name: 'b', data: 'y'));

      await service.delete('1');
      final all = await service.getAll();
      expect(all.map((o) => o.id), ['2']);
    });

    test('clear removes everything', () async {
      await service.save(const StorageObject(id: '1', name: 'a', data: 'x'));
      await service.clear();
      expect(await service.getAll(), isEmpty);
    });

    test('format field survives json roundtrip', () async {
      await service.save(
        const StorageObject(
          id: '1',
          name: 'qrCode',
          data: 'abc',
          format: 'qrCode',
        ),
      );

      final stored = await service.getAll();
      expect(stored.single.format, 'qrCode');
    });

    test('saveAll replaces collection preserving order', () async {
      await service.save(const StorageObject(id: '1', name: 'a', data: 'x'));
      await service.saveAll(const [
        StorageObject(id: '2', name: 'b', data: 'y'),
        StorageObject(id: '3', name: 'c', data: 'z'),
      ]);

      final all = await service.getAll();
      expect(all.map((o) => o.id), ['2', '3']);
    });
  });

  group('SharedPreferencesStorageService', () {
    late SharedPreferencesStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SharedPreferencesStorageService();
    });

    test('persists objects across instances', () async {
      await service.save(
        const StorageObject(id: '1', name: 'qrCode', data: 'hello'),
      );

      final second = SharedPreferencesStorageService();
      final all = await second.getAll();
      expect(all, hasLength(1));
      expect(all.single.data, 'hello');
    });

    test('delete and clear work', () async {
      await service.save(const StorageObject(id: '1', name: 'a', data: 'x'));
      await service.save(const StorageObject(id: '2', name: 'b', data: 'y'));

      await service.delete('1');
      expect(await service.getAll(), hasLength(1));

      await service.clear();
      expect(await service.getAll(), isEmpty);
    });

    test('saveAll persists order across instances', () async {
      await service.saveAll(const [
        StorageObject(id: '1', name: 'a', data: 'x'),
        StorageObject(id: '2', name: 'b', data: 'y'),
      ]);

      final second = SharedPreferencesStorageService();
      final all = await second.getAll();
      expect(all.map((o) => o.id), ['1', '2']);
    });
  });
}
