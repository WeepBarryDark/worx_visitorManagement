/// Paper Type Model for Brother Label Printers
/// Defines supported paper sizes for QL-820NWB and QL-720NW
class PaperType {
  final int labelNameIndex;
  final String name;
  final String description;
  final String dimensions;
  final bool isContinuous;
  final bool isSpecialTape; // true = Red/Black, false = Black/White

  const PaperType({
    required this.labelNameIndex,
    required this.name,
    required this.description,
    required this.dimensions,
    required this.isContinuous,
    this.isSpecialTape = false, // Default to standard black/white
  });

  /// Supported paper types for your Brother printer
  /// PROBLEM: labelNameIndex=17 always maps to W62RB (Red/Black)
  /// We use isSpecialTape to differentiate, but SDK ignores it
  static const List<PaperType> supportedTypes = [
    // DK-22205: Black on White continuous tape
    PaperType(
      labelNameIndex: 17,
      name: 'DK-22205 - 62mm Continuous White',
      description: 'Black on White continuous tape',
      dimensions: '62mm x 30.48m',
      isContinuous: true,
      isSpecialTape: false,
    ),

    // DK-22251: Black and Red on White continuous tape
    PaperType(
      labelNameIndex: 17,
      name: 'DK-22251 - 62mm Continuous Black/Red',
      description: 'Black and Red on White continuous tape',
      dimensions: '62mm x 15.24m',
      isContinuous: true,
      isSpecialTape: true,
    ),
  ];

  /// Get default paper type (62mm continuous)
  static PaperType get defaultType => supportedTypes[0];

  /// Find paper type by label name index
  static PaperType? fromLabelNameIndex(int index) {
    try {
      return supportedTypes.firstWhere(
        (type) => type.labelNameIndex == index,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'labelNameIndex': labelNameIndex,
      'name': name,
      'description': description,
      'dimensions': dimensions,
      'isContinuous': isContinuous,
      'isSpecialTape': isSpecialTape,
    };
  }

  /// Create from JSON
  factory PaperType.fromJson(Map<String, dynamic> json) {
    return PaperType(
      labelNameIndex: json['labelNameIndex'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      dimensions: json['dimensions'] as String,
      isContinuous: json['isContinuous'] as bool,
      isSpecialTape: (json['isSpecialTape'] as bool?) ?? false,
    );
  }

  /// Get color type display string
  String get colorType => isSpecialTape ? 'Red/Black' : 'Black/White';

  @override
  String toString() => '$name ($dimensions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaperType &&
           other.labelNameIndex == labelNameIndex &&
           other.isSpecialTape == isSpecialTape;
  }

  @override
  int get hashCode => Object.hash(labelNameIndex, isSpecialTape);
}
