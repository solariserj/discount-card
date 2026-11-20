import 'package:camera_app/viewmodels/scan_view_model.dart';
import 'package:camera_app/widgets/name_input_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _dialogShowing = false;

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
            child: MobileScanner(
              controller: vm.controller,
              onDetect: vm.handleDetection,
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
