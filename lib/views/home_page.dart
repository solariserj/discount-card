import 'package:camera_app/models/card_color_scheme.dart';
import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/viewmodels/scan_view_model.dart';
import 'package:camera_app/viewmodels/storage_view_model.dart';
import 'package:camera_app/views/scan_page.dart';
import 'package:camera_app/widgets/name_input_dialog.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:camera_app/utils/barcode_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openScanner(BuildContext context) async {
    context.read<StorageViewModel>().exitEditMode();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ScanViewModel(),
          child: const ScanPage(),
        ),
      ),
    );
    if (context.mounted) {
      await context.read<StorageViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discount Card App')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('scan_button'),
              onPressed: () => _openScanner(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR / Barcode'),
            ),
          ),
          const Divider(height: 1),
          Consumer<StorageViewModel>(
            builder: (context, vm, _) {
              if (vm.objects.isEmpty) return const SizedBox.shrink();
              final favorite = vm.objects.first;
              final kind = favorite.format.isNotEmpty
                  ? favorite.format
                  : favorite.name;
              final isQr = kind.toLowerCase().contains('qr');
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Container(
                  height: isQr ? 170 : 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: Row(
                          children: [
                            const Text(
                              'Favorite',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Text(
                                favorite.name,
                                key: const Key('favorite_name'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Center(
                            child: BarcodeWidget(
                              key: const Key('favorite_barcode'),
                              barcode: barcodeFor(favorite),
                              data: favorite.data,
                              drawText: false,
                              height: isQr ? 120 : 64,
                              errorBuilder: (context, error) =>
                                  const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Saved scans',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Consumer<StorageViewModel>(
                  builder: (context, vm, _) => TextButton(
                    key: const Key('edit_toggle_button'),
                    onPressed: vm.objects.isEmpty ? null : vm.toggleEditing,
                    child: Text(vm.isEditing ? 'Done' : 'Edit'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<StorageViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.objects.isEmpty) {
                  return const Center(child: Text('No saved scans yet'));
                }
                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: vm.objects.length,
                  onReorderItem: vm.reorderItems,
                  itemBuilder: (context, index) {
                    final object = vm.objects[index];
                    return _StorageObjectTile(
                      key: Key('scan_${object.id}'),
                      object: object,
                      index: index,
                      editing: vm.isEditing,
                      onDelete: () => vm.delete(object.id),
                      onRename: (newName, color) =>
                          vm.rename(object.id, newName, color: color),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageObjectTile extends StatelessWidget {
  const _StorageObjectTile({
    super.key,
    required this.object,
    required this.index,
    required this.editing,
    required this.onDelete,
    required this.onRename,
  });

  final StorageObject object;
  final int index;
  final bool editing;
  final VoidCallback onDelete;
  final void Function(String name, String? color) onRename;

  /// Icon matching the scanned code type: QR-style glyphs for QR codes and
  /// other 2D symbologies, a barcode glyph for 1D barcodes.
  static IconData _iconFor(StorageObject object) {
    final kind = (object.format.isNotEmpty ? object.format : object.name)
        .toLowerCase();
    if (kind.contains('qr')) return Icons.qr_code_2;
    if (kind.contains('datamatrix') ||
        kind.contains('pdf417') ||
        kind.contains('aztec')) {
      return Icons.qr_code;
    }
    return Icons.barcode_reader;
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    String? selectedColor;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => NameInputDialog(
        title: 'Rename',
        initialName: object.name,
        showColorPicker: true,
        initialScheme: object.color,
        onSchemeChanged: (id) => selectedColor = id,
      ),
    );
    if (newName != null) onRename(newName, selectedColor);
  }

  void _showBarcodeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _BarcodeDialog(object: object),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: CardColorScheme.fromId(object.color).color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: editing
              ? () => _showRenameDialog(context)
              : () => _showBarcodeDialog(context),
          leading: editing
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator),
                )
              : Icon(_iconFor(object)),
          title: Text(object.name),
          subtitle: Text(
            object.data,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: editing
              ? IconButton(
                  key: Key('delete_${object.id}'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                )
              : null,
        ),
      ),
    );
  }
}

class _BarcodeDialog extends StatelessWidget {
  const _BarcodeDialog({required this.object});

  final StorageObject object;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('barcode_dialog'),
      title: Text(
        object.name,
        key: const Key('barcode_name'),
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: .min,
        children: [
          BarcodeWidget(
            key: const Key('barcode_image'),
            barcode: barcodeFor(object),
            data: object.data,
            drawText: false,
            width: 260,
            height: 120,
            errorBuilder: (context, error) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Cannot render ${object.name}: $error'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            object.data,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
