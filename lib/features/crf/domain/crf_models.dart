import '../../../core/constants/app_enums.dart';

class DiseaseProfile {
  const DiseaseProfile({
    required this.id,
    required this.groupCode,
    required this.groupName,
    required this.tumorCode,
    required this.tumorName,
    required this.defaultTemplateId,
    required this.enabled,
  });

  final String id;
  final String groupCode;
  final String groupName;
  final String tumorCode;
  final String tumorName;
  final String defaultTemplateId;
  final bool enabled;

  String get displayName => '$groupName / $tumorName';
}

class CRFTemplate {
  const CRFTemplate({
    required this.id,
    required this.diseaseProfileId,
    required this.version,
    required this.title,
    required this.status,
    required this.sections,
    required this.fieldMappings,
  });

  final String id;
  final String diseaseProfileId;
  final String version;
  final String title;
  final CRFTemplateStatus status;
  final List<CRFSection> sections;
  final List<FieldMapping> fieldMappings;

  List<CRFField> get fields =>
      sections.expand((section) => section.allFields).toList(growable: false);

  List<CRFField> get searchableFields =>
      fields.where((field) => field.searchable).toList(growable: false);

  int get fieldCount => fields.length;

  int get blockingFieldCount => fields
      .where((field) => field.requiredLevel == RequiredLevel.blocking)
      .length;

  int get governanceFieldCount => fields
      .where((field) => field.governanceStatus == 'need_governance')
      .length;

  CRFField? fieldByCode(String fieldCode) {
    for (final field in fields) {
      if (field.fieldCode == fieldCode) return field;
    }
    return null;
  }
}

class CRFSection {
  const CRFSection({
    required this.code,
    required this.title,
    required this.level,
    this.children = const <CRFSection>[],
    this.fields = const <CRFField>[],
  });

  final String code;
  final String title;
  final int level;
  final List<CRFSection> children;
  final List<CRFField> fields;

  List<CRFField> get allFields => <CRFField>[
    ...fields,
    ...children.expand((child) => child.allFields),
  ];
}

class CRFField {
  const CRFField({
    required this.fieldCode,
    required this.path,
    required this.label,
    required this.dataType,
    required this.requiredLevel,
    this.options = const <String>[],
    this.unit,
    this.format,
    this.source,
    this.description,
    this.repeatable = false,
    this.searchable = false,
    this.governanceStatus,
  });

  final String fieldCode;
  final List<String> path;
  final String label;
  final CRFFieldType dataType;
  final RequiredLevel requiredLevel;
  final List<String> options;
  final String? unit;
  final String? format;
  final String? source;
  final String? description;
  final bool repeatable;
  final bool searchable;
  final String? governanceStatus;

  String get displayPath => path.join(' / ');

  bool get needsGovernance => governanceStatus == 'need_governance';
}

class CaseCRFValue {
  const CaseCRFValue({
    required this.caseId,
    required this.templateId,
    required this.fieldCode,
    required this.value,
    required this.status,
    required this.confidence,
    this.evidenceId,
    this.eventId,
    this.updatedAtLabel,
  });

  final String caseId;
  final String templateId;
  final String fieldCode;
  final String value;
  final CRFValueStatus status;
  final FieldConfidence confidence;
  final String? evidenceId;
  final String? eventId;
  final String? updatedAtLabel;

  bool get isComplete =>
      status == CRFValueStatus.filled || status == CRFValueStatus.notApplicable;

  CaseCRFValue copyWith({
    String? value,
    CRFValueStatus? status,
    FieldConfidence? confidence,
    String? evidenceId,
    String? eventId,
    String? updatedAtLabel,
  }) {
    return CaseCRFValue(
      caseId: caseId,
      templateId: templateId,
      fieldCode: fieldCode,
      value: value ?? this.value,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      evidenceId: evidenceId ?? this.evidenceId,
      eventId: eventId ?? this.eventId,
      updatedAtLabel: updatedAtLabel ?? this.updatedAtLabel,
    );
  }
}

class FieldMapping {
  const FieldMapping({
    required this.crfFieldCode,
    required this.canonicalEntity,
    required this.canonicalField,
    required this.mappingType,
    this.transformRule,
  });

  final String crfFieldCode;
  final String canonicalEntity;
  final String canonicalField;
  final FieldMappingType mappingType;
  final String? transformRule;

  String get displayImpact =>
      '$canonicalEntity.$canonicalField · ${mappingType.label}';
}

class CRFCompleteness {
  const CRFCompleteness({
    required this.totalCount,
    required this.completedCount,
    required this.blockingMissingCount,
    required this.recommendedMissingCount,
    required this.conflictCount,
    required this.governanceCount,
  });

  final int totalCount;
  final int completedCount;
  final int blockingMissingCount;
  final int recommendedMissingCount;
  final int conflictCount;
  final int governanceCount;

  double get rate => totalCount == 0 ? 0 : completedCount / totalCount;
}
