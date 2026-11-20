import 'package:camera_app/models/card_color_scheme.dart';
import 'package:material_ui/material_ui.dart';

/// Dialog with a single text field and Save/Cancel actions. When
/// [showColorPicker] is true, a row of color swatches lets the user pick a
/// [CardColorScheme]; changes are reported via [onSchemeChanged].
/// Pops with the entered text on Save, or null on Cancel.
class NameInputDialog extends StatefulWidget {
  const NameInputDialog({
    super.key,
    required this.title,
    required this.initialName,
    this.showColorPicker = false,
    this.initialScheme,
    this.onSchemeChanged,
  });

  final String title;
  final String initialName;
  final bool showColorPicker;
  final String? initialScheme;
  final ValueChanged<String>? onSchemeChanged;

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late final TextEditingController _controller;
  late String _selectedScheme;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _selectedScheme =
        widget.initialScheme ?? CardColorScheme.purple.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: .min,
        children: [
          TextField(
            key: const Key('name_field'),
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          if (widget.showColorPicker) ...[
            const SizedBox(height: 16),
            Wrap(
              key: const Key('color_picker'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scheme in CardColorScheme.values)
                  GestureDetector(
                    key: Key('color_${scheme.id}'),
                    onTap: () {
                      setState(() => _selectedScheme = scheme.id);
                      widget.onSchemeChanged?.call(scheme.id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedScheme == scheme.id
                              ? Colors.black87
                              : Colors.black26,
                          width: _selectedScheme == scheme.id ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('save_button'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
