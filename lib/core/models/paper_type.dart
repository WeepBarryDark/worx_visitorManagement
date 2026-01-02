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

  /// Common paper types for visitor badges
  /// Based on Brother QL series label name index specification
  /// Includes both Black/White and Red/Black versions
  static const List<PaperType> supportedTypes = [
    // ========== BLACK/WHITE PAPER ==========

    // Continuous length tape - most flexible
    PaperType(
      labelNameIndex: 17,
      name: '62mm Continuous (Black/White)',
      description: 'Continuous length tape',
      dimensions: '62mm width',
      isContinuous: true,
      isSpecialTape: false,
    ),

    // Pre-cut labels - specific sizes
    PaperType(
      labelNameIndex: 4,
      name: '62mm x 100mm (Black/White)',
      description: 'Pre-cut label',
      dimensions: '62mm x 100mm',
      isContinuous: false,
      isSpecialTape: false,
    ),

    PaperType(
      labelNameIndex: 5,
      name: '29mm x 90mm (Black/White)',
      description: 'Pre-cut address label',
      dimensions: '29mm x 90mm',
      isContinuous: false,
      isSpecialTape: false,
    ),

    PaperType(
      labelNameIndex: 8,
      name: '62mm x 29mm (Black/White)',
      description: 'Pre-cut small label',
      dimensions: '62mm x 29mm',
      isContinuous: false,
      isSpecialTape: false,
    ),

    PaperType(
      labelNameIndex: 15,
      name: '29mm Continuous (Black/White)',
      description: 'Continuous length tape (narrow)',
      dimensions: '29mm width',
      isContinuous: true,
      isSpecialTape: false,
    ),

    // ========== RED/BLACK PAPER ==========

    PaperType(
      labelNameIndex: 17,
      name: '62mm Continuous (Red/Black)',
      description: 'Continuous length tape (2-color)',
      dimensions: '62mm width',
      isContinuous: true,
      isSpecialTape: true,
    ),

    PaperType(
      labelNameIndex: 4,
      name: '62mm x 100mm (Red/Black)',
      description: 'Pre-cut label (2-color)',
      dimensions: '62mm x 100mm',
      isContinuous: false,
      isSpecialTape: true,
    ),

    PaperType(
      labelNameIndex: 5,
      name: '29mm x 90mm (Red/Black)',
      description: 'Pre-cut address label (2-color)',
      dimensions: '29mm x 90mm',
      isContinuous: false,
      isSpecialTape: true,
    ),

    PaperType(
      labelNameIndex: 8,
      name: '62mm x 29mm (Red/Black)',
      description: 'Pre-cut small label (2-color)',
      dimensions: '62mm x 29mm',
      isContinuous: false,
      isSpecialTape: true,
    ),

    PaperType(
      labelNameIndex: 15,
      name: '29mm Continuous (Red/Black)',
      description: 'Continuous length tape (2-color, narrow)',
      dimensions: '29mm width',
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
