import '../../case_detail/domain/case_models.dart';
import '../../../core/constants/app_enums.dart';

class SearchFilter {
  const SearchFilter({
    this.primarySite,
    this.tumorType,
    this.stage,
    this.lineOfTherapy,
    this.drugClass,
    this.hasLiverRisk,
    this.ecogMax,
    this.comorbidity,
    this.screeningStatusLabel,
    this.diseaseProfileId,
    this.crfTemplateId,
    this.crfConditions = const <CRFFilterCondition>[],
  });

  final String? primarySite;
  final String? tumorType;
  final String? stage;
  final int? lineOfTherapy;
  final String? drugClass;
  final bool? hasLiverRisk;
  final int? ecogMax;
  final String? comorbidity;
  final String? screeningStatusLabel;
  final String? diseaseProfileId;
  final String? crfTemplateId;
  final List<CRFFilterCondition> crfConditions;

  bool get hasActiveFilters =>
      primarySite != null ||
      tumorType != null ||
      stage != null ||
      lineOfTherapy != null ||
      drugClass != null ||
      hasLiverRisk != null ||
      ecogMax != null ||
      comorbidity != null ||
      screeningStatusLabel != null ||
      diseaseProfileId != null ||
      crfTemplateId != null ||
      crfConditions.isNotEmpty;

  SearchFilter copyWith({
    String? primarySite,
    String? tumorType,
    String? stage,
    int? lineOfTherapy,
    String? drugClass,
    bool? hasLiverRisk,
    int? ecogMax,
    String? comorbidity,
    String? screeningStatusLabel,
    String? diseaseProfileId,
    String? crfTemplateId,
    List<CRFFilterCondition>? crfConditions,
    bool clearPrimarySite = false,
    bool clearTumorType = false,
    bool clearStage = false,
    bool clearLineOfTherapy = false,
    bool clearDrugClass = false,
    bool clearLiverRisk = false,
    bool clearEcogMax = false,
    bool clearComorbidity = false,
    bool clearScreeningStatus = false,
    bool clearDiseaseProfile = false,
    bool clearCrfTemplate = false,
    bool clearCrfConditions = false,
  }) {
    return SearchFilter(
      primarySite: clearPrimarySite ? null : primarySite ?? this.primarySite,
      tumorType: clearTumorType ? null : tumorType ?? this.tumorType,
      stage: clearStage ? null : stage ?? this.stage,
      lineOfTherapy: clearLineOfTherapy
          ? null
          : lineOfTherapy ?? this.lineOfTherapy,
      drugClass: clearDrugClass ? null : drugClass ?? this.drugClass,
      hasLiverRisk: clearLiverRisk ? null : hasLiverRisk ?? this.hasLiverRisk,
      ecogMax: clearEcogMax ? null : ecogMax ?? this.ecogMax,
      comorbidity: clearComorbidity ? null : comorbidity ?? this.comorbidity,
      screeningStatusLabel: clearScreeningStatus
          ? null
          : screeningStatusLabel ?? this.screeningStatusLabel,
      diseaseProfileId: clearDiseaseProfile
          ? null
          : diseaseProfileId ?? this.diseaseProfileId,
      crfTemplateId: clearCrfTemplate
          ? null
          : crfTemplateId ?? this.crfTemplateId,
      crfConditions: clearCrfConditions
          ? const <CRFFilterCondition>[]
          : crfConditions ?? this.crfConditions,
    );
  }

  SearchFilter clear() => const SearchFilter();
}

class CRFFilterCondition {
  const CRFFilterCondition({
    required this.templateId,
    required this.fieldCode,
    required this.label,
    required this.operator,
    required this.value,
  });

  final String templateId;
  final String fieldCode;
  final String label;
  final CRFFilterOperator operator;
  final String value;

  String get displayLabel => '$label ${operator.label} $value';
}

class SearchResult {
  const SearchResult({required this.summary, required this.matchedReasons});

  final CaseSummary summary;
  final List<String> matchedReasons;
}
