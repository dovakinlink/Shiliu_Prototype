enum ScreeningStatus { notReady, partial, ready }

enum TaskType { missingField, conflictReview }

enum UploadSource { camera, pdf, voice, gallery }

enum UploadJobStage { queued, processing, extracted, needsReview }

enum FieldConfidence { verified, aiHigh, aiMedium, missing, conflict }

enum DocumentModality { image, pdf, audio, text }

enum MolecularStatus { positive, negative, notTested }

enum TimelineEventType {
  diagnosis,
  pathology,
  treatment,
  lab,
  imaging,
  adverseEvent,
  followUp,
  screening,
}

enum FieldChangeType { append, fill, update, conflict, unchanged }

enum FieldReviewDecision { acceptNew, keepOld, markConflict }

enum CRFTemplateStatus { draft, active, archived }

enum CRFFieldType { text, number, date, category, boolean, unknown }

enum RequiredLevel { blocking, recommended, optional }

enum CRFValueStatus { filled, missing, conflict, notApplicable }

enum FieldMappingType { direct, normalize, derive, aggregate }

enum TaskScope { canonical, crf, governance }

enum CRFFilterOperator { equals, contains, gte, lte }

extension ScreeningStatusX on ScreeningStatus {
  String get label => switch (this) {
    ScreeningStatus.notReady => '不可初筛',
    ScreeningStatus.partial => '部分可初筛',
    ScreeningStatus.ready => '可初筛',
  };
}

extension TaskTypeX on TaskType {
  String get label => switch (this) {
    TaskType.missingField => '缺字段补录',
    TaskType.conflictReview => '冲突核对',
  };
}

extension UploadSourceX on UploadSource {
  String get label => switch (this) {
    UploadSource.camera => '拍照采集',
    UploadSource.pdf => 'PDF 上传',
    UploadSource.voice => '语音录入',
    UploadSource.gallery => '相册导入',
  };
}

extension UploadJobStageX on UploadJobStage {
  String get label => switch (this) {
    UploadJobStage.queued => '已创建',
    UploadJobStage.processing => 'AI 处理中',
    UploadJobStage.extracted => '结构化摘要',
    UploadJobStage.needsReview => '待人工确认',
  };
}

extension FieldConfidenceX on FieldConfidence {
  String get label => switch (this) {
    FieldConfidence.verified => '人工确认',
    FieldConfidence.aiHigh => '高置信',
    FieldConfidence.aiMedium => '需复核',
    FieldConfidence.missing => '缺失',
    FieldConfidence.conflict => '冲突',
  };
}

extension MolecularStatusX on MolecularStatus {
  String get label => switch (this) {
    MolecularStatus.positive => '阳性',
    MolecularStatus.negative => '阴性',
    MolecularStatus.notTested => '未检',
  };
}

extension DocumentModalityX on DocumentModality {
  String get label => switch (this) {
    DocumentModality.image => '图片',
    DocumentModality.pdf => 'PDF',
    DocumentModality.audio => '语音',
    DocumentModality.text => '文本',
  };
}

extension TimelineEventTypeX on TimelineEventType {
  String get label => switch (this) {
    TimelineEventType.diagnosis => '确诊',
    TimelineEventType.pathology => '病理',
    TimelineEventType.treatment => '治疗',
    TimelineEventType.lab => '检验',
    TimelineEventType.imaging => '影像',
    TimelineEventType.adverseEvent => '不良事件',
    TimelineEventType.followUp => '随访',
    TimelineEventType.screening => '筛查',
  };
}

extension FieldChangeTypeX on FieldChangeType {
  String get label => switch (this) {
    FieldChangeType.append => '新增',
    FieldChangeType.fill => '补齐',
    FieldChangeType.update => '更新',
    FieldChangeType.conflict => '冲突',
    FieldChangeType.unchanged => '一致',
  };
}

extension FieldReviewDecisionX on FieldReviewDecision {
  String get label => switch (this) {
    FieldReviewDecision.acceptNew => '采用新值',
    FieldReviewDecision.keepOld => '保留旧值',
    FieldReviewDecision.markConflict => '标记冲突',
  };
}

extension CRFTemplateStatusX on CRFTemplateStatus {
  String get label => switch (this) {
    CRFTemplateStatus.draft => '草稿',
    CRFTemplateStatus.active => '启用中',
    CRFTemplateStatus.archived => '已归档',
  };
}

extension CRFFieldTypeX on CRFFieldType {
  String get label => switch (this) {
    CRFFieldType.text => '文本',
    CRFFieldType.number => '数值',
    CRFFieldType.date => '日期',
    CRFFieldType.category => '类别',
    CRFFieldType.boolean => '有/无',
    CRFFieldType.unknown => '待治理',
  };
}

extension RequiredLevelX on RequiredLevel {
  String get label => switch (this) {
    RequiredLevel.blocking => '阻断',
    RequiredLevel.recommended => '推荐',
    RequiredLevel.optional => '可选',
  };
}

extension CRFValueStatusX on CRFValueStatus {
  String get label => switch (this) {
    CRFValueStatus.filled => '已填',
    CRFValueStatus.missing => '缺失',
    CRFValueStatus.conflict => '冲突',
    CRFValueStatus.notApplicable => '不适用',
  };
}

extension FieldMappingTypeX on FieldMappingType {
  String get label => switch (this) {
    FieldMappingType.direct => '直接回写',
    FieldMappingType.normalize => '归一化',
    FieldMappingType.derive => '派生',
    FieldMappingType.aggregate => '聚合',
  };
}

extension TaskScopeX on TaskScope {
  String get label => switch (this) {
    TaskScope.canonical => '通用主干',
    TaskScope.crf => '专病 CRF',
    TaskScope.governance => '字段治理',
  };
}

extension CRFFilterOperatorX on CRFFilterOperator {
  String get label => switch (this) {
    CRFFilterOperator.equals => '等于',
    CRFFilterOperator.contains => '包含',
    CRFFilterOperator.gte => '大于等于',
    CRFFilterOperator.lte => '小于等于',
  };
}
