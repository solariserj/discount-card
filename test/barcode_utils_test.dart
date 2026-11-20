import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/utils/barcode_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('barcodeFor', () {
    test('maps known format names to matching barcode types', () {
      final ean = barcodeFor(
        const StorageObject(
          id: '1',
          name: 'ean13',
          data: '5901234123457',
          format: 'ean13',
        ),
      );
      final code128 = barcodeFor(
        const StorageObject(
          id: '2',
          name: 'code128',
          data: 'ABC',
          format: 'code128',
        ),
      );

      expect(ean.runtimeType, isNot(code128.runtimeType));
      expect(ean.runtimeType, isNot(
        barcodeFor(
          const StorageObject(id: '3', name: 'x', data: 'y'),
        ).runtimeType,
      ));
    });

    test('prefers format field over name', () {
      // Renamed record: name is custom but format still says ean13.
      final renamed = barcodeFor(
        const StorageObject(
          id: '1',
          name: 'My product',
          data: '5901234123457',
          format: 'ean13',
        ),
      );
      final direct = barcodeFor(
        const StorageObject(
          id: '2',
          name: 'ean13',
          data: '5901234123457',
          format: 'ean13',
        ),
      );

      expect(renamed.runtimeType, direct.runtimeType);
    });

    test('falls back to name when format is empty', () {
      final legacy = barcodeFor(
        const StorageObject(id: '1', name: 'ean13', data: '1234567890128'),
      );
      final direct = barcodeFor(
        const StorageObject(
          id: '2',
          name: 'ean13',
          data: '5901234123457',
          format: 'ean13',
        ),
      );

      expect(legacy.runtimeType, direct.runtimeType);
    });

    test('unknown names fall back to QR code', () {
      final custom = barcodeFor(
        const StorageObject(id: '1', name: 'My label', data: 'anything'),
      );
      final qr = barcodeFor(
        const StorageObject(
          id: '2',
          name: 'qrCode',
          data: 'x',
          format: 'qrCode',
        ),
      );

      expect(custom.runtimeType, qr.runtimeType);
    });
  });
}
