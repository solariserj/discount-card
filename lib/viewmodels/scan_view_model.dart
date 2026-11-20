import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera_app/models/card_color_scheme.dart';
import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/scan_service.dart';
import 'package:camera_app/services/shared_preferences_storage_service.dart';
import 'package:camera_app/services/storage_service.dart';

/// A code detected by the camera that is waiting for the user to confirm
/// a name before being saved.
class PendingScan {
  const PendingScan({required this.value, required this.format});

  final String value;
  final String format;
}

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({ScanService? service, StorageService? storage})
    : _service = service ?? ScanService(),
      _storage = storage ?? SharedPreferencesStorageService() {
    controller = _service.createController();
  }

  final ScanService _service;
  final StorageService _storage;
  final Random _random = Random();

  /// Owns the camera controller; disposed with this view model.
  late final MobileScannerController controller;

  /// Scanned values, most recent first.
  final List<String> scans = <String>[];

  /// Objects persisted by this session, most recent first.
  final List<StorageObject> savedObjects = <StorageObject>[];

  /// The latest detection awaiting user confirmation, if any.
  PendingScan? pendingScan;

  String? _lastValue;
  String? storageError;

  Future<void> handleDetection(BarcodeCapture capture) async {
    if (pendingScan != null) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      if (value == null || value.isEmpty || value == _lastValue) continue;
      _lastValue = value;
      pendingScan = PendingScan(value: value, format: barcode.format.name);
      notifyListeners();
      return;
    }
  }

  /// Saves [pendingScan] under [name] (empty names fall back to the format
  /// name) and clears the pending state.
  Future<void> confirmScan(String name) async {
    final pending = pendingScan;
    if (pending == null) return;
    final trimmed = name.trim();
    final schemes = CardColorScheme.values;
    final object = StorageObject(
      id: '${DateTime.now().microsecondsSinceEpoch}_${savedObjects.length}',
      name: trimmed.isEmpty ? pending.format : trimmed,
      data: pending.value,
      format: pending.format,
      color: schemes[_random.nextInt(schemes.length)].id,
    );
    try {
      await _storage.save(object);
      savedObjects.insert(0, object);
      scans.insert(0, '${pending.format}: ${pending.value}');
      storageError = null;
    } catch (e) {
      storageError = 'Failed to save scan: $e';
    }
    pendingScan = null;
    _lastValue = null;
    notifyListeners();
  }

  /// Discards [pendingScan] without saving and allows the same code to be
  /// detected again.
  void cancelPendingScan() {
    pendingScan = null;
    _lastValue = null;
    notifyListeners();
  }

  Future<void> toggleTorch() => controller.toggleTorch();

  Future<void> switchCamera() => controller.switchCamera();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
