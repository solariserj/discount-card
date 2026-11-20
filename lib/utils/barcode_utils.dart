import 'package:barcode_widget/barcode_widget.dart';
import 'package:camera_app/models/storage_object.dart';

/// Maps a stored scan back to a drawable [Barcode].
///
/// [StorageObject.format] records the scanner's format name (e.g. `qrCode`,
/// `ean13`). For records saved before that field existed — or renamed — we
/// fall back to [StorageObject.name] and finally to a QR code, which can
/// encode any text.
Barcode barcodeFor(StorageObject object) {
  final kind = object.format.isNotEmpty ? object.format : object.name;
  switch (kind) {
    case 'ean13':
      return Barcode.ean13();
    case 'ean8':
      return Barcode.ean8();
    case 'upcA':
      return Barcode.upcA();
    case 'upcE':
      return Barcode.upcE();
    case 'code128':
      return Barcode.code128();
    case 'code39':
      return Barcode.code39();
    case 'code93':
      return Barcode.code93();
    case 'codabar':
      return Barcode.codabar();
    case 'dataMatrix':
      return Barcode.dataMatrix();
    case 'pdf417':
      return Barcode.pdf417();
    case 'aztec':
      return Barcode.aztec();
    case 'itf14':
      return Barcode.itf14();
    case 'qrCode':
    case 'microQrCode':
    default:
      return Barcode.qrCode();
  }
}
