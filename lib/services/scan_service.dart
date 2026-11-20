import 'package:mobile_scanner/mobile_scanner.dart';

/// Creates and configures the camera scanner used by [ScanViewModel].
class ScanService {
  /// Barcode formats the scanner will recognize: QR codes and common 1D/2D
  /// barcode symbologies.
  static const List<BarcodeFormat> supportedFormats = <BarcodeFormat>[
    BarcodeFormat.qrCode,
    BarcodeFormat.microQrCode,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.pdf417,
    BarcodeFormat.aztec,
    BarcodeFormat.itf14,
  ];

  MobileScannerController createController({bool autoStart = true}) {
    return MobileScannerController(
      formats: supportedFormats,
      detectionSpeed: DetectionSpeed.normal,
      autoStart: autoStart,
    );
  }
}
