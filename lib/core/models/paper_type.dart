/// Paper Type Model for Brother Label Printers
/// Defines supported paper sizes for QL-820NWB and QL-720NW
class PaperType {
  final int labelNameIndex;
  final String code; // DK-22205, DK-22251, etc.
  final String name;
  final String description;
  final String width;
  final bool isContinuous;
  final String material; // Clear Film, White Paper, Yellow Film, etc.
  final bool isRemovable;
  final bool isNonAdhesive;
  final bool isSpecialTape; // true = Red/Black, false = Black/White
  final List<String> supportedModels; // Which printer models support this paper

  const PaperType({
    required this.labelNameIndex,
    required this.code,
    required this.name,
    required this.description,
    required this.width,
    required this.isContinuous,
    required this.material,
    this.isRemovable = false,
    this.isNonAdhesive = false,
    this.isSpecialTape = false,
    required this.supportedModels,
  });

  /// All supported paper types for Brother QL series printers
  static const List<PaperType> allPaperTypes = [
    // DK-22113: 62mm Continuous Clear Film (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-22113',
      name: 'DK-22113',
      description: '62mm Continuous Clear Film',
      width: '62mm',
      isContinuous: true,
      material: 'Clear Film',
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-22205: 62mm Continuous White Paper (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-22205',
      name: 'DK-22205',
      description: '62mm Continuous White Paper',
      width: '62mm',
      isContinuous: true,
      material: 'White Paper',
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-22212: 62mm Continuous White Film (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-22212',
      name: 'DK-22212',
      description: '62mm Continuous White Film',
      width: '62mm',
      isContinuous: true,
      material: 'White Film',
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-22606: 62mm Continuous Yellow Film (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-22606',
      name: 'DK-22606',
      description: '62mm Continuous Yellow Film',
      width: '62mm',
      isContinuous: true,
      material: 'Yellow Film',
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-44205: 62mm Continuous White Paper (Removable) (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-44205',
      name: 'DK-44205',
      description: '62mm Continuous White Paper (Removable)',
      width: '62mm',
      isContinuous: true,
      material: 'White Paper',
      isRemovable: true,
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-44605: 62mm Continuous Yellow Paper (Removable) (Both models)
    PaperType(
      labelNameIndex: 15,
      code: 'DK-44605',
      name: 'DK-44605',
      description: '62mm Continuous Yellow Paper (Removable)',
      width: '62mm',
      isContinuous: true,
      material: 'Yellow Paper',
      isRemovable: true,
      supportedModels: ['QL-820NWB', 'QL-720NW'],
    ),

    // DK-N55224: 54mm Continuous White Paper (Non-adhesive) (QL-820NWB only)
    PaperType(
      labelNameIndex: 14,
      code: 'DK-N55224',
      name: 'DK-N55224',
      description: '54mm Continuous White Paper (Non-adhesive)',
      width: '54mm',
      isContinuous: true,
      material: 'White Paper',
      isNonAdhesive: true,
      supportedModels: ['QL-820NWB'], // Only QL-820NWB
    ),

    // DK-22251: 62mm Continuous Black/Red on White (QL-820NWB only)
    PaperType(
      labelNameIndex: 17,
      code: 'DK-22251',
      name: 'DK-22251',
      description: '62mm Continuous Black/Red on White',
      width: '62mm',
      isContinuous: true,
      material: 'White Paper',
      isSpecialTape: true,
      supportedModels: ['QL-820NWB'], // Only QL-820NWB
    ),
  ];

  /// Get paper types supported by a specific printer model
  static List<PaperType> getPaperTypesForModel(String model) {
    final normalizedModel = model.toUpperCase().trim();
    return allPaperTypes
        .where((paper) => paper.supportedModels
            .any((m) => m.toUpperCase() == normalizedModel))
        .toList();
  }

  /// Get default paper type (DK-22205 - most common)
  static PaperType get defaultType => allPaperTypes[1]; // DK-22205

  /// Find paper type by code
  static PaperType? fromCode(String code) {
    try {
      return allPaperTypes.firstWhere(
        (type) => type.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find paper type by label name index
  static PaperType? fromLabelNameIndex(int index) {
    try {
      return allPaperTypes.firstWhere(
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
      'code': code,
      'name': name,
      'description': description,
      'width': width,
      'isContinuous': isContinuous,
      'material': material,
      'isRemovable': isRemovable,
      'isNonAdhesive': isNonAdhesive,
      'isSpecialTape': isSpecialTape,
      'supportedModels': supportedModels,
    };
  }

  /// Create from JSON
  factory PaperType.fromJson(Map<String, dynamic> json) {
    return PaperType(
      labelNameIndex: json['labelNameIndex'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      width: json['width'] as String,
      isContinuous: json['isContinuous'] as bool,
      material: json['material'] as String,
      isRemovable: (json['isRemovable'] as bool?) ?? false,
      isNonAdhesive: (json['isNonAdhesive'] as bool?) ?? false,
      isSpecialTape: (json['isSpecialTape'] as bool?) ?? false,
      supportedModels: List<String>.from(json['supportedModels'] as List),
    );
  }

  /// Get color type display string
  String get colorType => isSpecialTape ? 'Red/Black' : 'Black/White';

  /// Get special features display string
  String get specialFeatures {
    final features = <String>[];
    if (isRemovable) features.add('Removable');
    if (isNonAdhesive) features.add('Non-adhesive');
    if (isSpecialTape) features.add('Red/Black');
    return features.isEmpty ? 'Standard' : features.join(', ');
  }

  /// Full display name with all details
  String get fullDisplayName => '$code - $width $material${_featureSuffix()}';

  String _featureSuffix() {
    if (isRemovable) return ' (Removable)';
    if (isNonAdhesive) return ' (Non-adhesive)';
    if (isSpecialTape) return ' (Black/Red)';
    return '';
  }

  @override
  String toString() => fullDisplayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaperType && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
