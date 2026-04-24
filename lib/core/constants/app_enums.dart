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
