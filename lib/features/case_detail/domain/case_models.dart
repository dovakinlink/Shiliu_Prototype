import '../../../core/constants/app_enums.dart';

class CaseSummary {
  const CaseSummary({
    required this.id,
    required this.patientName,
    required this.patientCode,
    required this.primarySite,
    required this.tumorType,
    required this.histology,
    required this.stage,
    required this.lineOfTherapy,
    required this.currentRegimen,
    required this.diseaseGroup,
    required this.screeningStatus,
    required this.ecog,
    required this.hasLiverRisk,
    required this.tags,
    required this.lastUpdatedLabel,
  });

  final String id;
  final String patientName;
  final String patientCode;
  final String primarySite;
  final String tumorType;
  final String histology;
  final String stage;
  final int lineOfTherapy;
  final String currentRegimen;
  final String diseaseGroup;
  final ScreeningStatus screeningStatus;
  final int ecog;
  final bool hasLiverRisk;
  final List<String> tags;
  final String lastUpdatedLabel;

  CaseSummary copyWith({
    String? histology,
    String? stage,
    int? lineOfTherapy,
    String? currentRegimen,
    ScreeningStatus? screeningStatus,
    int? ecog,
    bool? hasLiverRisk,
    List<String>? tags,
    String? lastUpdatedLabel,
  }) {
    return CaseSummary(
      id: id,
      patientName: patientName,
      patientCode: patientCode,
      primarySite: primarySite,
      tumorType: tumorType,
      histology: histology ?? this.histology,
      stage: stage ?? this.stage,
      lineOfTherapy: lineOfTherapy ?? this.lineOfTherapy,
      currentRegimen: currentRegimen ?? this.currentRegimen,
      diseaseGroup: diseaseGroup,
      screeningStatus: screeningStatus ?? this.screeningStatus,
      ecog: ecog ?? this.ecog,
      hasLiverRisk: hasLiverRisk ?? this.hasLiverRisk,
      tags: tags ?? this.tags,
      lastUpdatedLabel: lastUpdatedLabel ?? this.lastUpdatedLabel,
    );
  }
}

// ---------------------------------------------------------------------------
// Diagnosis & Staging
// ---------------------------------------------------------------------------

class DiagnosisInfo {
  const DiagnosisInfo({
    required this.primarySiteCode,
    required this.icd10Code,
    required this.pathologyDiagnosis,
    required this.stageSystem,
    required this.tnmT,
    required this.tnmN,
    required this.tnmM,
    required this.ajccStage,
  });

  final String primarySiteCode;
  final String icd10Code;
  final String pathologyDiagnosis;
  final String stageSystem;
  final String tnmT;
  final String tnmN;
  final String tnmM;
  final String ajccStage;
}

// ---------------------------------------------------------------------------
// Molecular Testing & Biomarkers
// ---------------------------------------------------------------------------

class MolecularResult {
  const MolecularResult({
    required this.gene,
    required this.variant,
    required this.status,
    required this.sampleType,
  });

  final String gene;
  final String variant;
  final MolecularStatus status;
  final String sampleType;
}

class BiomarkerResult {
  const BiomarkerResult({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}

// ---------------------------------------------------------------------------
// Treatment Lines & Drug Exposure
// ---------------------------------------------------------------------------

class TreatmentLine {
  const TreatmentLine({
    required this.lineNo,
    required this.regimenName,
    required this.regimenType,
    required this.drugs,
    required this.startDate,
    this.endDate,
  });

  final int lineNo;
  final String regimenName;
  final String regimenType;
  final List<DrugExposure> drugs;
  final String startDate;
  final String? endDate;
}

class DrugExposure {
  const DrugExposure({
    required this.drugGeneric,
    required this.drugClass,
    required this.startDate,
    this.endDate,
  });

  final String drugGeneric;
  final String drugClass;
  final String startDate;
  final String? endDate;
}

// ---------------------------------------------------------------------------
// Lab Panels & Results
// ---------------------------------------------------------------------------

class LabPanel {
  const LabPanel({
    required this.collectionDate,
    required this.results,
  });

  final String collectionDate;
  final List<LabResult> results;
}

class LabResult {
  const LabResult({
    required this.testName,
    required this.value,
    required this.unit,
    this.refLow,
    this.refHigh,
    required this.isAbnormal,
    this.ctcaeGrade,
  });

  final String testName;
  final double value;
  final String unit;
  final double? refLow;
  final double? refHigh;
  final bool isAbnormal;
  final int? ctcaeGrade;
}

// ---------------------------------------------------------------------------
// Imaging & Response Assessment
// ---------------------------------------------------------------------------

class ImagingRecord {
  const ImagingRecord({
    required this.studyType,
    required this.date,
    required this.impression,
    this.response,
  });

  final String studyType;
  final String date;
  final String impression;
  final String? response;
}

// ---------------------------------------------------------------------------
// Adverse Events
// ---------------------------------------------------------------------------

class AdverseEventRecord {
  const AdverseEventRecord({
    required this.aeTerm,
    required this.grade,
    required this.startDate,
    required this.attribution,
  });

  final String aeTerm;
  final int grade;
  final String startDate;
  final String attribution;
}

// ---------------------------------------------------------------------------
// Vital Signs & Infection Status
// ---------------------------------------------------------------------------

class VitalSignsInfo {
  const VitalSignsInfo({
    required this.ecog,
    this.weight,
  });

  final int ecog;
  final double? weight;
}

class InfectionInfo {
  const InfectionInfo({
    required this.hbvStatus,
  });

  final String hbvStatus;
}

// ---------------------------------------------------------------------------
// Case Detail (expanded)
// ---------------------------------------------------------------------------

class CaseDetail {
  const CaseDetail({
    required this.summary,
    required this.birthYear,
    required this.sex,
    required this.diagnosisDate,
    required this.diseaseStatus,
    required this.metastaticSites,
    required this.comorbidities,
    required this.alerts,
    required this.timeline,
    required this.structuredFields,
    required this.evidenceDocuments,
    required this.diagnosis,
    required this.molecularResults,
    required this.biomarkers,
    required this.treatmentLines,
    required this.labPanels,
    required this.imagingRecords,
    required this.adverseEvents,
    required this.vitalSigns,
    this.infectionStatus,
  });

  final CaseSummary summary;
  final int birthYear;
  final String sex;
  final String diagnosisDate;
  final String diseaseStatus;
  final String metastaticSites;
  final List<String> comorbidities;
  final List<String> alerts;
  final List<TimelineEvent> timeline;
  final List<StructuredField> structuredFields;
  final List<EvidenceDocument> evidenceDocuments;

  final DiagnosisInfo diagnosis;
  final List<MolecularResult> molecularResults;
  final List<BiomarkerResult> biomarkers;
  final List<TreatmentLine> treatmentLines;
  final List<LabPanel> labPanels;
  final List<ImagingRecord> imagingRecords;
  final List<AdverseEventRecord> adverseEvents;
  final VitalSignsInfo vitalSigns;
  final InfectionInfo? infectionStatus;

  CaseDetail copyWith({
    CaseSummary? summary,
    String? diseaseStatus,
    String? metastaticSites,
    List<String>? alerts,
    List<TimelineEvent>? timeline,
    List<StructuredField>? structuredFields,
    List<EvidenceDocument>? evidenceDocuments,
  }) {
    return CaseDetail(
      summary: summary ?? this.summary,
      birthYear: birthYear,
      sex: sex,
      diagnosisDate: diagnosisDate,
      diseaseStatus: diseaseStatus ?? this.diseaseStatus,
      metastaticSites: metastaticSites ?? this.metastaticSites,
      comorbidities: comorbidities,
      alerts: alerts ?? this.alerts,
      timeline: timeline ?? this.timeline,
      structuredFields: structuredFields ?? this.structuredFields,
      evidenceDocuments: evidenceDocuments ?? this.evidenceDocuments,
      diagnosis: diagnosis,
      molecularResults: molecularResults,
      biomarkers: biomarkers,
      treatmentLines: treatmentLines,
      labPanels: labPanels,
      imagingRecords: imagingRecords,
      adverseEvents: adverseEvents,
      vitalSigns: vitalSigns,
      infectionStatus: infectionStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline, Evidence & Structured Fields (unchanged)
// ---------------------------------------------------------------------------

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.type,
    required this.description,
    required this.fieldIds,
    required this.evidenceIds,
    this.isImportant = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String dateLabel;
  final TimelineEventType type;
  final String description;
  final List<String> fieldIds;
  final List<String> evidenceIds;
  final bool isImportant;
}

class EvidenceAnchor {
  const EvidenceAnchor({
    required this.label,
    required this.locator,
    required this.excerpt,
  });

  final String label;
  final String locator;
  final String excerpt;
}

class EvidenceDocument {
  const EvidenceDocument({
    required this.id,
    required this.title,
    required this.modality,
    required this.source,
    required this.dateLabel,
    required this.summary,
    required this.anchor,
    required this.linkedFieldIds,
    required this.eventId,
  });

  final String id;
  final String title;
  final DocumentModality modality;
  final String source;
  final String dateLabel;
  final String summary;
  final EvidenceAnchor anchor;
  final List<String> linkedFieldIds;
  final String eventId;
}

class StructuredField {
  const StructuredField({
    required this.id,
    required this.label,
    required this.value,
    required this.group,
    required this.confidence,
    required this.eventId,
    required this.evidenceId,
    this.isRequired = false,
    this.isBlocking = false,
  });

  final String id;
  final String label;
  final String value;
  final String group;
  final FieldConfidence confidence;
  final String eventId;
  final String evidenceId;
  final bool isRequired;
  final bool isBlocking;

  StructuredField copyWith({
    String? value,
    FieldConfidence? confidence,
  }) {
    return StructuredField(
      id: id,
      label: label,
      value: value ?? this.value,
      group: group,
      confidence: confidence ?? this.confidence,
      eventId: eventId,
      evidenceId: evidenceId,
      isRequired: isRequired,
      isBlocking: isBlocking,
    );
  }
}
