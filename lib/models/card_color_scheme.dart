import 'package:material_ui/material_ui.dart';

/// Named color schemes that can be assigned to a saved scan. [color] is a
/// light tint used as the cell background so the text stays readable.
enum CardColorScheme {
  purple,
  blue,
  green,
  orange,
  red,
  pink,
  teal,
  amber,
  indigo,
  cyan,
  lime,
  brown,
  crimson,
  azure;

  String get id => name;

  Color get color => switch (this) {
    purple => const Color(0xFFE1BEE7),
    blue => const Color(0xFFBBDEFB),
    green => const Color(0xFFC8E6C9),
    orange => const Color(0xFFFFE0B2),
    red => const Color(0xFFFFCDD2),
    pink => const Color(0xFFF8BBD0),
    teal => const Color(0xFFB2DFDB),
    amber => const Color(0xFFFFF9C4),
    indigo => const Color(0xFFC5CAE9),
    cyan => const Color(0xFFB2EBF2),
    lime => const Color(0xFFDCEDC8),
    brown => const Color(0xFFD7CCC8),
    crimson => const Color(0xFFE57373),
    azure => const Color(0xFF64B5F6),
  };

  static CardColorScheme fromId(String? id) {
    for (final scheme in values) {
      if (scheme.id == id) return scheme;
    }
    return CardColorScheme.purple;
  }
}
