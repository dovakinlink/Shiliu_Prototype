import '../../../core/constants/app_enums.dart';

class ExtractionDetail {
  const ExtractionDetail({
    required this.fieldName,
    required this.value,
    required this.confidence,
    this.sourceLocator,
    this.sourceExcerpt,
    this.changeType = FieldChangeType.append,
    this.existingValue,
    this.existingFieldId,
  });

  final String fieldName;
  final String value;
  final FieldConfidence confidence;
  final String? sourceLocator;
  final String? sourceExcerpt;
  final FieldChangeType changeType;
  final String? existingValue;
  final String? existingFieldId;

  ExtractionDetail copyWith({
    FieldChangeType? changeType,
    String? existingValue,
    String? existingFieldId,
  }) {
    return ExtractionDetail(
      fieldName: fieldName,
      value: value,
      confidence: confidence,
      sourceLocator: sourceLocator,
      sourceExcerpt: sourceExcerpt,
      changeType: changeType ?? this.changeType,
      existingValue: existingValue ?? this.existingValue,
      existingFieldId: existingFieldId ?? this.existingFieldId,
    );
  }
}

class UploadJob {
  const UploadJob({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.documentType,
    required this.source,
    required this.stage,
    required this.createdAtLabel,
    required this.description,
    required this.extractedHighlights,
    required this.pendingReviewFields,
    this.extractionDetails = const <ExtractionDetail>[],
  });

  final String id;
  final String patientId;
  final String patientName;
  final String documentType;
  final UploadSource source;
  final UploadJobStage stage;
  final String createdAtLabel;
  final String description;
  final List<String> extractedHighlights;
  final List<String> pendingReviewFields;
  final List<ExtractionDetail> extractionDetails;

  UploadJob copyWith({
    UploadJobStage? stage,
    List<String>? extractedHighlights,
    List<String>? pendingReviewFields,
    List<ExtractionDetail>? extractionDetails,
  }) {
    return UploadJob(
      id: id,
      patientId: patientId,
      patientName: patientName,
      documentType: documentType,
      source: source,
      stage: stage ?? this.stage,
      createdAtLabel: createdAtLabel,
      description: description,
      extractedHighlights: extractedHighlights ?? this.extractedHighlights,
      pendingReviewFields: pendingReviewFields ?? this.pendingReviewFields,
      extractionDetails: extractionDetails ?? this.extractionDetails,
    );
  }
}
