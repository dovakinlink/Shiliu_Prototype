import '../../case_detail/domain/case_models.dart';

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

  bool get hasActiveFilters =>
      primarySite != null ||
      tumorType != null ||
      stage != null ||
      lineOfTherapy != null ||
      drugClass != null ||
      hasLiverRisk != null ||
      ecogMax != null ||
      comorbidity != null ||
      screeningStatusLabel != null;

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
    bool clearPrimarySite = false,
    bool clearTumorType = false,
    bool clearStage = false,
    bool clearLineOfTherapy = false,
    bool clearDrugClass = false,
    bool clearLiverRisk = false,
    bool clearEcogMax = false,
    bool clearComorbidity = false,
    bool clearScreeningStatus = false,
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
    );
  }

  SearchFilter clear() => const SearchFilter();
}

class SearchResult {
  const SearchResult({
    required this.summary,
    required this.matchedReasons,
  });

  final CaseSummary summary;
  final List<String> matchedReasons;
}
