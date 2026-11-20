/// Default color scheme id used for records without a stored color.
const String kDefaultCardColor = 'purple';

/// A single persisted item: an [id], a human-readable [name], the scanned
/// [data] payload, the [format] of the scanned code (e.g. `qrCode`,
/// `ean13`) and the [color] scheme id used for its card background.
class StorageObject {
  const StorageObject({
    required this.id,
    required this.name,
    required this.data,
    this.format = '',
    this.color = kDefaultCardColor,
  });

  final String id;
  final String name;
  final String data;

  /// Scanner-reported format name; empty for records saved before this
  /// field existed.
  final String format;

  /// [CardColorScheme] id for the card background.
  final String color;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'data': data,
    'format': format,
    'color': color,
  };

  factory StorageObject.fromJson(Map<String, dynamic> json) {
    return StorageObject(
      id: json['id'] as String,
      name: json['name'] as String,
      data: json['data'] as String,
      format: json['format'] as String? ?? '',
      color: json['color'] as String? ?? kDefaultCardColor,
    );
  }

  StorageObject copyWith({String? name, String? format, String? color}) {
    return StorageObject(
      id: id,
      name: name ?? this.name,
      data: data,
      format: format ?? this.format,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StorageObject &&
      other.id == id &&
      other.name == name &&
      other.data == data &&
      other.format == format &&
      other.color == color;

  @override
  int get hashCode => Object.hash(id, name, data, format, color);

  @override
  String toString() =>
      'StorageObject(id: $id, name: $name, data: $data, format: $format, '
      'color: $color)';
}
