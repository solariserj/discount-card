import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/in_memory_storage_service.dart';
import 'package:camera_app/viewmodels/scan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

BarcodeCapture captureWith(
  String value, {
  BarcodeFormat format = BarcodeFormat.qrCode,
}) {
  return BarcodeCapture(
    barcodes: [Barcode(rawValue: value, displayValue: value, format: format)],
  );
}

void main() {
  group('ScanViewModel', () {
    late ScanViewModel vm;
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
      vm = ScanViewModel(storage: storage);
    });

    tearDown(() {
      vm.dispose();
    });

    test('detection parks a pending scan without saving', () async {
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.handleDetection(captureWith('https://example.com'));

      expect(vm.pendingScan?.value, 'https://example.com');
      expect(vm.pendingScan?.format, 'qrCode');
      expect(vm.scans, isEmpty);
      expect(vm.savedObjects, isEmpty);
      expect(await storage.getAll(), isEmpty);
      expect(notified, 1);
    });

    test('confirmScan saves object with user name and format', () async {
      await vm.handleDetection(captureWith('ABC123'));
      await vm.confirmScan('My label');

      expect(vm.pendingScan, isNull);
      expect(vm.scans, ['qrCode: ABC123']);
      expect(vm.savedObjects.single.name, 'My label');
      expect(vm.savedObjects.single.data, 'ABC123');
      expect(vm.savedObjects.single.format, 'qrCode');
      expect(vm.storageError, isNull);

      final stored = await storage.getAll();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'My label');
    });

    test('confirmScan falls back to format name when name is empty', () async {
      await vm.handleDetection(captureWith('123', format: BarcodeFormat.ean13));
      await vm.confirmScan('   ');

      expect(vm.savedObjects.single.name, 'ean13');
      expect(vm.savedObjects.single.format, 'ean13');
    });

    test(
      'cancelPendingScan discards without saving and allows rescan',
      () async {
        await vm.handleDetection(captureWith('ABC123'));
        vm.cancelPendingScan();

        expect(vm.pendingScan, isNull);
        expect(await storage.getAll(), isEmpty);

        // Same code can be detected again after cancel.
        await vm.handleDetection(captureWith('ABC123'));
        expect(vm.pendingScan?.value, 'ABC123');
      },
    );

    test('ignores detections while a scan is pending', () async {
      await vm.handleDetection(captureWith('first'));
      await vm.handleDetection(captureWith('second'));

      expect(vm.pendingScan?.value, 'first');
    });

    test('ignores empty detections and repeats while pending', () async {
      await vm.handleDetection(
        BarcodeCapture(barcodes: [const Barcode(format: BarcodeFormat.qrCode)]),
      );
      expect(vm.pendingScan, isNull);

      await vm.handleDetection(captureWith('ABC123'));
      await vm.handleDetection(captureWith('ABC123'));
      await vm.handleDetection(captureWith('ABC123'));

      expect(vm.pendingScan?.value, 'ABC123');
      expect(vm.savedObjects, isEmpty);
    });

    test('falls back to displayValue when rawValue is missing', () async {
      await vm.handleDetection(
        BarcodeCapture(
          barcodes: [
            const Barcode(
              displayValue: 'display-only',
              format: BarcodeFormat.ean13,
            ),
          ],
        ),
      );

      expect(vm.pendingScan?.value, 'display-only');
      expect(vm.pendingScan?.format, 'ean13');
    });

    test('newest confirmed scan is first in the list', () async {
      await vm.handleDetection(captureWith('first'));
      await vm.confirmScan('a');
      await vm.handleDetection(captureWith('second'));
      await vm.confirmScan('b');

      expect(vm.scans, ['qrCode: second', 'qrCode: first']);
      expect(vm.savedObjects.first.data, 'second');
    });

    test('handles multiple barcodes in one capture', () async {
      await vm.handleDetection(
        BarcodeCapture(
          barcodes: [
            const Barcode(rawValue: 'one', format: BarcodeFormat.qrCode),
            const Barcode(rawValue: 'two', format: BarcodeFormat.code128),
          ],
        ),
      );
      await vm.confirmScan('multi');

      // Only the first barcode in the capture becomes pending.
      expect(vm.savedObjects.single.data, 'one');
    });

    test('sets storageError when saving fails', () async {
      final failingVm = ScanViewModel(storage: _FailingStorageService());
      addTearDown(failingVm.dispose);

      await failingVm.handleDetection(captureWith('fail'));
      await failingVm.confirmScan('x');

      expect(failingVm.storageError, contains('Failed to save scan'));
      expect(failingVm.savedObjects, isEmpty);
      expect(failingVm.pendingScan, isNull);
    });
  });
}

class _FailingStorageService extends InMemoryStorageService {
  @override
  Future<void> save(StorageObject object) => throw StateError('disk full');
}
