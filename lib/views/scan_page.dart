import 'package:camera_app/viewmodels/scan_view_model.dart';
import 'package:camera_app/widgets/name_input_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.imagePicker});

  /// Optional image picker override for tests.
  final ImagePicker? imagePicker;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _dialogShowing = false;
  bool _analyzingImage = false;

  void _maybeShowNameDialog(ScanViewModel vm) {
    final pending = vm.pendingScan;
    if (pending == null || _dialogShowing) return;
    _dialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final name = await showDialog<String>(
        context: context,
        builder: (context) => NameInputDialog(
          title: 'Name this ${pending.format}',
          initialName: pending.format,
        ),
      );
      _dialogShowing = false;
      if (!mounted) return;
      if (name == null) {
        context.read<ScanViewModel>().cancelPendingScan();
      } else {
        await context.read<ScanViewModel>().confirmScan(name);
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  Future<void> _pickImageFromLibrary() async {
    if (_analyzingImage) return;
    setState(() => _analyzingImage = true);
    try {
      final picker = widget.imagePicker ?? ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final found = await context.read<ScanViewModel>().analyzeImage(file.path);
      if (!found && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            key: const Key('no_barcode_dialog'),
            title: const Text('No code found'),
            content: const Text('On this image no QR/Barcodes'),
            actions: [
              TextButton(
                key: const Key('no_barcode_close_button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      // When a code is found, analyzeImage sets pendingScan and the
      // name dialog is shown by _maybeShowNameDialog on the next build.
    } finally {
      if (mounted) setState(() => _analyzingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    _maybeShowNameDialog(vm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR / Barcode'),
        actions: [
          IconButton(
            key: const Key('torch_button'),
            icon: const Icon(Icons.flash_on),
            onPressed: vm.toggleTorch,
          ),
          IconButton(
            key: const Key('switch_camera_button'),
            icon: const Icon(Icons.cameraswitch),
            onPressed: vm.switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: vm.controller,
                  onDetect: vm.handleDetection,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton.extended(
                      key: const Key('library_button'),
                      onPressed: _analyzingImage ? null : _pickImageFromLibrary,
                      icon: _analyzingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: const Text('Photo from library'),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: vm.scans.isEmpty
                ? const Text(
                    'Point the camera at a QR code or barcode',
                    style: TextStyle(color: Colors.white70),
                  )
                : Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      for (final scan in vm.scans.take(5))
                        Text(scan, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
