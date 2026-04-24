import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../features/case_detail/domain/case_models.dart';
import '../../features/intake/domain/upload_job.dart';
import '../../features/screening/domain/screening_models.dart';
import 'mock_seed_data.dart';

class MockAppState {
  const MockAppState({
    required this.cases,
    required this.uploads,
  });

  final List<MockCaseBundle> cases;
  final List<UploadJob> uploads;

  MockAppState copyWith({
    List<MockCaseBundle>? cases,
    List<UploadJob>? uploads,
  }) {
    return MockAppState(
      cases: cases ?? this.cases,
      uploads: uploads ?? this.uploads,
    );
  }
}

final mockAppStoreProvider = NotifierProvider<MockAppStore, MockAppState>(
  MockAppStore.new,
);

class MockAppStore extends Notifier<MockAppState> {
  @override
  MockAppState build() {
    return MockAppState(
      cases: buildSeedCaseBundles(),
      uploads: buildSeedUploadJobs(),
    );
  }

  MockCaseBundle createCase({
    required String patientName,
    required String sex,
    required int birthYear,
    required String primarySite,
    required String tumorType,
    String? histology,
    String? stage,
  }) {
    final nextIndex = state.cases.length + 1;
    final caseId = 'case-${nextIndex.toString().padLeft(3, '0')}';
    final patientCode = 'SHL-${nextIndex.toString().padLeft(3, '0')}';
    final now = DateTime.now();
    final dateLabel =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final diseaseGroup = _inferDiseaseGroup(primarySite);

    final summary = CaseSummary(
      id: caseId,
      patientName: patientName,
      patientCode: patientCode,
      primarySite: primarySite,
      tumorType: tumorType,
      histology: histology ?? '待补录',
      stage: stage ?? '待分期',
      lineOfTherapy: 0,
      currentRegimen: '待补录',
      diseaseGroup: diseaseGroup,
      screeningStatus: ScreeningStatus.notReady,
      ecog: 0,
      hasLiverRisk: false,
      tags: <String>[diseaseGroup, '新建病例'],
      lastUpdatedLabel: dateLabel,
    );

    final detail = CaseDetail(
      summary: summary,
      birthYear: birthYear,
      sex: sex,
      diagnosisDate: dateLabel,
      diseaseStatus: '新建',
      metastaticSites: '待补录',
      comorbidities: const <String>[],
      alerts: const <String>['新建病例，尚无采集资料，请上传文档以启动 AI 结构化流程。'],
      timeline: const <TimelineEvent>[],
      structuredFields: const <StructuredField>[],
      evidenceDocuments: const <EvidenceDocument>[],
      diagnosis: DiagnosisInfo(
        primarySiteCode: '',
        icd10Code: '',
        pathologyDiagnosis: '待补录',
        stageSystem: '',
        tnmT: '', tnmN: '', tnmM: '',
        ajccStage: stage ?? '待分期',
      ),
      molecularResults: const <MolecularResult>[],
      biomarkers: const <BiomarkerResult>[],
      treatmentLines: const <TreatmentLine>[],
      labPanels: const <LabPanel>[],
      imagingRecords: const <ImagingRecord>[],
      adverseEvents: const <AdverseEventRecord>[],
      vitalSigns: const VitalSignsInfo(ecog: 0),
    );

    final screening = ScreeningSnapshot(
      caseId: caseId,
      projectTitle: 'YABY 小丫筛查快照',
      status: ScreeningStatus.notReady,
      keyFacts: <String>[
        '$primarySite · ${stage ?? '待分期'}',
        '0 线 · 待补录',
        'ECOG 0',
        '肝功待查',
      ],
      blockingFields: const <String>['ECOG评分', '当前方案', '临床分期'],
      reminderFields: const <String>['关键分子标志物', '转移部位'],
      tasks: <CompletenessTask>[
        CompletenessTask(
          id: '$caseId-task-missing-blocking',
          caseId: caseId,
          title: '补齐核心筛查字段',
          type: TaskType.missingField,
          description: '新建病例，请上传资料并补齐阻断型字段。',
          fields: const <String>['ECOG评分', '当前方案', '临床分期'],
          owner: '录入用户',
          dueLabel: '今日内',
          isBlocking: true,
        ),
        CompletenessTask(
          id: '$caseId-task-missing-reminder',
          caseId: caseId,
          title: '完善提醒字段',
          type: TaskType.missingField,
          description: '建议补齐项目筛查所需的提醒字段，提升快照完整度。',
          fields: const <String>['关键分子标志物', '转移部位'],
          owner: '项目秘书',
          dueLabel: '24 小时',
        ),
      ],
    );

    final bundle = MockCaseBundle(detail: detail, screening: screening);
    state = state.copyWith(cases: <MockCaseBundle>[bundle, ...state.cases]);
    return bundle;
  }

  UploadJob createUpload({
    required String patientId,
    required String documentType,
    required UploadSource source,
    required String description,
  }) {
    final caseBundle = state.cases.firstWhere((bundle) => bundle.detail.summary.id == patientId);
    final job = UploadJob(
      id: 'upload-${(state.uploads.length + 1).toString().padLeft(3, '0')}',
      patientId: patientId,
      patientName: caseBundle.detail.summary.patientName,
      documentType: documentType,
      source: source,
      stage: UploadJobStage.queued,
      createdAtLabel: '2026-04-14 19:${(state.uploads.length + 11).toString().padLeft(2, '0')}',
      description: description,
      extractedHighlights: const <String>[],
      pendingReviewFields: const <String>[],
    );

    state = state.copyWith(uploads: <UploadJob>[job, ...state.uploads]);
    return job;
  }

  void advanceUpload(String jobId) {
    state = state.copyWith(
      uploads: state.uploads.map((job) {
        if (job.id != jobId) {
          return job;
        }
        switch (job.stage) {
          case UploadJobStage.queued:
            return job.copyWith(stage: UploadJobStage.processing);
          case UploadJobStage.processing:
            return job.copyWith(
              stage: UploadJobStage.extracted,
              extractedHighlights: const <String>[
                '识别出病理类型',
                '识别出当前方案',
                '识别出最近一次实验室时间点',
              ],
            );
          case UploadJobStage.extracted:
            return job.copyWith(
              stage: UploadJobStage.needsReview,
              pendingReviewFields: const <String>[
                'ECOG评分',
                '关键分子标志物',
              ],
            );
          case UploadJobStage.needsReview:
            return job;
        }
      }).toList(growable: false),
    );
  }

  void advanceToNeedsReview(String jobId) {
    state = state.copyWith(
      uploads: state.uploads.map((job) {
        if (job.id != jobId) return job;

        final rawDetails = _extractionDetailsFor(job.documentType);
        final caseBundle = state.cases
            .where((b) => b.detail.summary.id == job.patientId)
            .firstOrNull;
        final existingFields = caseBundle?.detail.structuredFields ?? const [];

        final details = rawDetails.map((d) {
          return _classifyExtraction(d, existingFields);
        }).toList(growable: false);

        final highlights = details
            .map((d) => '识别出 ${d.fieldName}')
            .toList(growable: false);
        final pending = details
            .where((d) =>
                d.confidence == FieldConfidence.aiMedium ||
                d.confidence == FieldConfidence.conflict ||
                d.changeType == FieldChangeType.update ||
                d.changeType == FieldChangeType.conflict)
            .map((d) => d.fieldName)
            .toList(growable: false);
        return job.copyWith(
          stage: UploadJobStage.needsReview,
          extractedHighlights: highlights,
          pendingReviewFields: pending,
          extractionDetails: details,
        );
      }).toList(growable: false),
    );
  }

  void confirmUploadReview(
    String jobId, {
    Map<String, FieldReviewDecision> decisions = const {},
  }) {
    final job = state.uploads.where((j) => j.id == jobId).firstOrNull;
    if (job == null) return;

    final bundleIndex = state.cases.indexWhere(
      (b) => b.detail.summary.id == job.patientId,
    );
    if (bundleIndex < 0) {
      state = state.copyWith(
        uploads:
            state.uploads.where((j) => j.id != jobId).toList(growable: false),
      );
      return;
    }

    var bundle = state.cases[bundleIndex];
    var summary = bundle.detail.summary;
    var detail = bundle.detail;

    final now = DateTime.now();
    final dateLabel =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ts = now.millisecondsSinceEpoch;
    final newEventId = '${job.patientId}-event-upload-$ts';
    final newEvidenceId = '${job.patientId}-evidence-upload-$ts';

    final newFieldIds = <String>[];
    final updatedFields = List<StructuredField>.of(detail.structuredFields);

    for (final ext in job.extractionDetails) {
      final decision =
          decisions[ext.fieldName] ?? FieldReviewDecision.acceptNew;

      if (ext.changeType == FieldChangeType.unchanged) continue;

      if (decision == FieldReviewDecision.keepOld) continue;

      if (decision == FieldReviewDecision.markConflict) {
        if (ext.existingFieldId != null) {
          final idx = updatedFields.indexWhere((f) => f.id == ext.existingFieldId);
          if (idx >= 0) {
            updatedFields[idx] = updatedFields[idx].copyWith(
              confidence: FieldConfidence.conflict,
            );
          }
        }
        continue;
      }

      if (ext.changeType == FieldChangeType.fill ||
          ext.changeType == FieldChangeType.update) {
        if (ext.existingFieldId != null) {
          final idx =
              updatedFields.indexWhere((f) => f.id == ext.existingFieldId);
          if (idx >= 0) {
            updatedFields[idx] = updatedFields[idx].copyWith(
              value: ext.value,
              confidence: FieldConfidence.verified,
            );
            newFieldIds.add(updatedFields[idx].id);
            summary =
                _syncSummary(summary, updatedFields[idx].label, ext.value);
          }
        }
      } else if (ext.changeType == FieldChangeType.append) {
        final fieldId = '${job.patientId}-field-${ext.fieldName}-$ts';
        updatedFields.add(StructuredField(
          id: fieldId,
          label: ext.fieldName,
          value: ext.value,
          group: _inferFieldGroup(ext.fieldName),
          confidence: FieldConfidence.verified,
          eventId: newEventId,
          evidenceId: newEvidenceId,
        ));
        newFieldIds.add(fieldId);
        summary = _syncSummary(summary, ext.fieldName, ext.value);
      }
    }

    final newEvent = TimelineEvent(
      id: newEventId,
      title: '${job.documentType}采集入库',
      subtitle: '${job.source.label} · AI 识别 + 人工确认',
      dateLabel: dateLabel,
      type: _mapDocTypeToEventType(job.documentType),
      description: job.description,
      fieldIds: newFieldIds,
      evidenceIds: <String>[newEvidenceId],
      isImportant: true,
    );

    final newEvidence = EvidenceDocument(
      id: newEvidenceId,
      title: job.documentType,
      modality: _mapSourceToModality(job.source),
      source: job.source.label,
      dateLabel: dateLabel,
      summary: '通过${job.source.label}采集，AI 结构化识别后人工确认入库。',
      anchor: EvidenceAnchor(
        label: job.documentType,
        locator: '采集任务 ${job.id}',
        excerpt: job.description,
      ),
      linkedFieldIds: newFieldIds,
      eventId: newEventId,
    );

    final updatedTimeline = <TimelineEvent>[newEvent, ...detail.timeline];
    final updatedEvidence = <EvidenceDocument>[
      newEvidence,
      ...detail.evidenceDocuments,
    ];

    summary = summary.copyWith(lastUpdatedLabel: dateLabel);

    final filledLabels = job.extractionDetails
        .where((d) =>
            d.changeType == FieldChangeType.fill &&
            (decisions[d.fieldName] ?? FieldReviewDecision.acceptNew) ==
                FieldReviewDecision.acceptNew)
        .map((d) => d.fieldName)
        .toSet();

    const fieldToScreeningLabel = <String, List<String>>{
      '病理类型': ['病理类型'],
      'ECOG评分': ['ECOG评分'],
      '当前方案': ['当前方案'],
      '临床分期': ['临床分期'],
      '关键分子标志物': ['关键分子标志物'],
      'PD-L1 TPS': ['关键分子标志物'],
      'EGFR 突变': ['关键分子标志物'],
      'ALK 融合': ['关键分子标志物'],
      '转移部位': ['转移部位'],
    };

    final resolvedScreeningLabels = <String>{};
    for (final label in filledLabels) {
      final mapped = fieldToScreeningLabel[label];
      if (mapped != null) resolvedScreeningLabels.addAll(mapped);
    }

    final newBlocking = bundle.screening.blockingFields
        .where((f) => !resolvedScreeningLabels.contains(f))
        .toList(growable: false);
    final newReminder = bundle.screening.reminderFields
        .where((f) => !resolvedScreeningLabels.contains(f))
        .toList(growable: false);

    final updatedTasks = bundle.screening.tasks.map((task) {
      if (task.type != TaskType.missingField) return task;
      final remaining = task.fields
          .where((f) => !resolvedScreeningLabels.contains(f))
          .toList(growable: false);
      return task.copyWith(
        isCompleted: remaining.isEmpty,
        fields: remaining,
      );
    }).toList(growable: false);

    final hasConflictDecision = decisions.values
        .any((d) => d == FieldReviewDecision.markConflict);
    final conflictTasks = <CompletenessTask>[];
    if (hasConflictDecision) {
      final conflictFields = decisions.entries
          .where((e) => e.value == FieldReviewDecision.markConflict)
          .map((e) => e.key)
          .toList(growable: false);
      conflictTasks.add(CompletenessTask(
        id: '${job.patientId}-task-conflict-$ts',
        caseId: job.patientId,
        title: '采集数据冲突核对',
        type: TaskType.conflictReview,
        description: '新采集数据与已有数据存在冲突，需人工裁决。',
        fields: conflictFields,
        owner: '录入用户',
        dueLabel: '24 小时',
      ));
    }

    final normalizedScreening = _normalizeScreening(
      bundle.screening.copyWith(
        blockingFields: newBlocking,
        reminderFields: newReminder,
        tasks: [...updatedTasks, ...conflictTasks],
        keyFacts: <String>[
          '${summary.primarySite} · ${summary.stage}',
          '${summary.lineOfTherapy} 线 · ${summary.currentRegimen}',
          'ECOG ${summary.ecog}',
          summary.hasLiverRisk ? '伴肝功异常' : '肝功稳定',
        ],
      ),
    );

    detail = detail.copyWith(
      summary: summary.copyWith(screeningStatus: normalizedScreening.status),
      structuredFields: updatedFields,
      timeline: updatedTimeline,
      evidenceDocuments: updatedEvidence,
    );

    final updatedCases = List<MockCaseBundle>.of(state.cases);
    updatedCases[bundleIndex] = bundle.copyWith(
      detail: detail,
      screening: normalizedScreening,
    );

    state = state.copyWith(
      cases: updatedCases,
      uploads:
          state.uploads.where((j) => j.id != jobId).toList(growable: false),
    );
  }

  void supplementFields(String caseId, Map<String, String> values) {
    state = state.copyWith(
      cases: state.cases.map((bundle) {
        if (bundle.detail.summary.id != caseId) {
          return bundle;
        }
        return _applySupplement(bundle, values);
      }).toList(growable: false),
    );
  }

  void resolveTask(String taskId, {String? resolvedValue}) {
    state = state.copyWith(
      cases: state.cases.map((bundle) {
        final tasks = bundle.screening.tasks;
        final hasTask = tasks.any((task) => task.id == taskId);
        if (!hasTask) {
          return bundle;
        }

        final updatedTasks = tasks.map((task) {
          if (task.id == taskId) {
            return task.copyWith(isCompleted: true);
          }
          return task;
        }).toList(growable: false);

        final isConflictResolution = updatedTasks.any(
          (task) => task.id == taskId && task.type == TaskType.conflictReview,
        );

        var summary = bundle.detail.summary;
        final updatedFields = bundle.detail.structuredFields.map((field) {
          if (field.label == 'ECOG评分' && isConflictResolution) {
            if (resolvedValue != null) {
              summary = summary.copyWith(
                ecog: int.tryParse(resolvedValue) ?? summary.ecog,
              );
            }
            return field.copyWith(
              confidence: FieldConfidence.verified,
              value: resolvedValue ?? field.value,
            );
          }
          return field;
        }).toList(growable: false);

        final normalized = _normalizeScreening(
          bundle.screening.copyWith(tasks: updatedTasks),
        );
        return bundle.copyWith(
          detail: bundle.detail.copyWith(
            structuredFields: updatedFields,
            summary: summary.copyWith(
              screeningStatus: normalized.status,
            ),
          ),
          screening: normalized,
        );
      }).toList(growable: false),
    );
  }
}

List<ExtractionDetail> _extractionDetailsFor(String documentType) {
  const table = <String, List<ExtractionDetail>>{
    '病理报告': <ExtractionDetail>[
      ExtractionDetail(fieldName: '病理类型', value: '肺腺癌', confidence: FieldConfidence.aiHigh, sourceLocator: '第 1 页 · 段落 2', sourceExcerpt: '右肺下叶穿刺活检：腺癌，中分化，浸润性生长。'),
      ExtractionDetail(fieldName: '分化程度', value: '中分化', confidence: FieldConfidence.aiHigh, sourceLocator: '第 1 页 · 段落 2', sourceExcerpt: '肿瘤细胞呈腺管状排列，中分化。'),
      ExtractionDetail(fieldName: 'PD-L1 TPS', value: '70%', confidence: FieldConfidence.aiHigh, sourceLocator: '第 2 页 · 框 01', sourceExcerpt: 'PD-L1 (22C3) TPS = 70%，阳性。'),
      ExtractionDetail(fieldName: 'EGFR 突变', value: 'L858R', confidence: FieldConfidence.aiMedium, sourceLocator: '第 2 页 · 框 03', sourceExcerpt: 'EGFR 基因 21 号外显子 L858R 突变，丰度 15.2%。'),
      ExtractionDetail(fieldName: 'ALK 融合', value: '阴性', confidence: FieldConfidence.aiHigh, sourceLocator: '第 2 页 · 框 04', sourceExcerpt: 'ALK (Ventana D5F3) 阴性。'),
      ExtractionDetail(fieldName: 'Ki-67', value: '40%', confidence: FieldConfidence.aiMedium, sourceLocator: '第 1 页 · 框 05', sourceExcerpt: 'Ki-67 增殖指数约 40%。'),
    ],
    '影像报告': <ExtractionDetail>[
      ExtractionDetail(fieldName: '检查类型', value: '胸腹盆增强 CT', confidence: FieldConfidence.aiHigh, sourceLocator: '报告头 · 行 1', sourceExcerpt: '胸腹盆增强 CT 扫描。'),
      ExtractionDetail(fieldName: '原发灶大小', value: '3.2×2.8cm', confidence: FieldConfidence.aiHigh, sourceLocator: '第 1 页 · 段落 3', sourceExcerpt: '右肺下叶占位约 3.2×2.8cm，较前缩小约 15%。'),
      ExtractionDetail(fieldName: '疗效评估', value: 'PR', confidence: FieldConfidence.aiMedium, sourceLocator: '第 2 页 · 结论', sourceExcerpt: '综合评估：部分缓解 (PR)，建议继续当前方案。'),
      ExtractionDetail(fieldName: '转移部位', value: '纵隔淋巴结', confidence: FieldConfidence.aiHigh, sourceLocator: '第 1 页 · 段落 4', sourceExcerpt: '纵隔 4R、7 组淋巴结肿大，短径 1.2cm。'),
      ExtractionDetail(fieldName: '新发病灶', value: '未见', confidence: FieldConfidence.aiHigh, sourceLocator: '第 2 页 · 结论', sourceExcerpt: '未见新发转移灶。'),
    ],
    '随访语音': <ExtractionDetail>[
      ExtractionDetail(fieldName: 'ECOG评分', value: '1', confidence: FieldConfidence.aiMedium, sourceLocator: '语音 0:32', sourceExcerpt: '患者自述体力尚可，日常活动基本自理。'),
      ExtractionDetail(fieldName: '体重变化', value: '较上次减轻 1.5kg', confidence: FieldConfidence.aiHigh, sourceLocator: '语音 0:45', sourceExcerpt: '体重 54.5 公斤，上次 56 公斤。'),
      ExtractionDetail(fieldName: '不良反应', value: '乏力 I 级', confidence: FieldConfidence.aiMedium, sourceLocator: '语音 1:12', sourceExcerpt: '患者诉轻度乏力，不影响日常生活。'),
      ExtractionDetail(fieldName: '用药依从性', value: '规律服药', confidence: FieldConfidence.aiHigh, sourceLocator: '语音 1:38', sourceExcerpt: '口服药物按时服用，未漏服。'),
    ],
    '实验室检查': <ExtractionDetail>[
      ExtractionDetail(fieldName: 'ALT', value: '128 U/L', confidence: FieldConfidence.aiHigh, sourceLocator: '检验单 · 行 3', sourceExcerpt: 'ALT 128 U/L ↑（参考 7-40）。'),
      ExtractionDetail(fieldName: 'AST', value: '96 U/L', confidence: FieldConfidence.aiHigh, sourceLocator: '检验单 · 行 4', sourceExcerpt: 'AST 96 U/L ↑（参考 13-35）。'),
      ExtractionDetail(fieldName: '肝功状态', value: 'Grade 2 肝损伤', confidence: FieldConfidence.aiMedium, sourceLocator: '综合判读', sourceExcerpt: 'ALT/AST 升高达 CTCAE 2 级，考虑免疫相关性肝损伤可能。'),
      ExtractionDetail(fieldName: 'WBC', value: '5.8×10⁹/L', confidence: FieldConfidence.aiHigh, sourceLocator: '检验单 · 行 8', sourceExcerpt: 'WBC 5.8×10⁹/L（参考 3.5-9.5）。'),
      ExtractionDetail(fieldName: 'HGB', value: '118 g/L', confidence: FieldConfidence.aiHigh, sourceLocator: '检验单 · 行 10', sourceExcerpt: 'HGB 118 g/L（参考 115-150）。'),
    ],
  };
  return table[documentType] ?? table['病理报告']!;
}

MockCaseBundle _applySupplement(
  MockCaseBundle bundle,
  Map<String, String> values,
) {
  var summary = bundle.detail.summary;
  var detail = bundle.detail;
  final normalizedValues = values.map(
    (key, value) => MapEntry(key.trim(), value.trim()),
  )..removeWhere((key, value) => value.isEmpty);

  final updatedFields = detail.structuredFields.map((field) {
    if (!normalizedValues.containsKey(field.label)) {
      return field;
    }

    final nextValue = normalizedValues[field.label]!;
    if (field.label == '当前方案') {
      summary = summary.copyWith(currentRegimen: nextValue);
    }
    if (field.label == '病理类型') {
      summary = summary.copyWith(histology: nextValue);
    }
    if (field.label == 'ECOG评分') {
      summary = summary.copyWith(ecog: int.tryParse(nextValue) ?? summary.ecog);
    }
    return field.copyWith(
      value: nextValue,
      confidence: FieldConfidence.verified,
    );
  }).toList(growable: false);

  if (normalizedValues.containsKey('转移部位')) {
    detail = detail.copyWith(
      metastaticSites: normalizedValues['转移部位'],
    );
  }

  final resolvedBlocking = bundle.screening.blockingFields
      .where((field) => !normalizedValues.containsKey(field))
      .toList(growable: false);
  final resolvedReminder = bundle.screening.reminderFields
      .where((field) => !normalizedValues.containsKey(field))
      .toList(growable: false);
  final updatedTasks = bundle.screening.tasks.map((task) {
    final remainingFields = task.fields
        .where((field) => !normalizedValues.containsKey(field))
        .toList(growable: false);
    if (remainingFields.length != task.fields.length && task.type == TaskType.missingField) {
      return task.copyWith(
        isCompleted: remainingFields.isEmpty,
        fields: remainingFields,
      );
    }
    return task;
  }).toList(growable: false);

  final normalizedScreening = _normalizeScreening(
    bundle.screening.copyWith(
      blockingFields: resolvedBlocking,
      reminderFields: resolvedReminder,
      tasks: updatedTasks,
      keyFacts: <String>[
        '${summary.primarySite} · ${summary.stage}',
        '${summary.lineOfTherapy} 线 · ${summary.currentRegimen}',
        'ECOG ${summary.ecog}',
        summary.hasLiverRisk ? '伴肝功异常' : '肝功稳定',
      ],
    ),
  );

  return bundle.copyWith(
    detail: detail.copyWith(
      summary: summary.copyWith(screeningStatus: normalizedScreening.status),
      structuredFields: updatedFields,
    ),
    screening: normalizedScreening,
  );
}

ScreeningSnapshot _normalizeScreening(ScreeningSnapshot snapshot) {
  final openTasks = snapshot.tasks
      .where((task) => !task.isCompleted)
      .toList(growable: false);
  final hasBlocking = snapshot.blockingFields.isNotEmpty;
  final hasReminders = snapshot.reminderFields.isNotEmpty;
  final hasConflict = openTasks.any((task) => task.type == TaskType.conflictReview);
  final status = hasBlocking
      ? ScreeningStatus.notReady
      : (hasReminders || hasConflict)
          ? ScreeningStatus.partial
          : ScreeningStatus.ready;

  return snapshot.copyWith(
    status: status,
    tasks: openTasks,
  );
}

CaseSummary _syncSummary(CaseSummary summary, String label, String value) {
  switch (label) {
    case '当前方案':
      return summary.copyWith(currentRegimen: value);
    case '病理类型':
      return summary.copyWith(histology: value);
    case 'ECOG评分':
      return summary.copyWith(ecog: int.tryParse(value) ?? summary.ecog);
    case '肝功状态':
      return summary.copyWith(
          hasLiverRisk: value.contains('Grade') || value.contains('异常'));
    default:
      return summary;
  }
}

String _inferFieldGroup(String fieldName) {
  const mapping = <String, String>{
    '病理类型': '诊断',
    '分化程度': '诊断',
    '临床分期': '分期',
    '当前方案': '治疗',
    'ECOG评分': '筛查',
    '肝功状态': '安全性',
    '关键分子标志物': '标志物',
    'PD-L1 TPS': '标志物',
    'EGFR 突变': '标志物',
    'ALK 融合': '标志物',
    'Ki-67': '标志物',
    '检查类型': '影像',
    '原发灶大小': '影像',
    '疗效评估': '影像',
    '转移部位': '影像',
    '新发病灶': '影像',
    '体重变化': '体征',
    '不良反应': '安全性',
    '用药依从性': '治疗',
    'ALT': '检验',
    'AST': '检验',
    'WBC': '检验',
    'HGB': '检验',
  };
  return mapping[fieldName] ?? '其他';
}

ExtractionDetail _classifyExtraction(
  ExtractionDetail raw,
  List<StructuredField> existingFields,
) {
  const fieldNameToLabel = <String, String>{
    '病理类型': '病理类型',
    '临床分期': '临床分期',
    '当前方案': '当前方案',
    'ECOG评分': 'ECOG评分',
    '肝功状态': '肝功状态',
    '关键分子标志物': '关键分子标志物',
    '转移部位': '转移部位',
    'PD-L1 TPS': '关键分子标志物',
    'EGFR 突变': '关键分子标志物',
    'ALK 融合': '关键分子标志物',
    '疗效评估': '临床分期',
  };

  final mappedLabel = fieldNameToLabel[raw.fieldName] ?? raw.fieldName;
  final match = existingFields
      .where((f) => f.label == mappedLabel)
      .firstOrNull;

  if (match == null) {
    return raw.copyWith(changeType: FieldChangeType.append);
  }

  final existingVal = match.value;

  if (match.confidence == FieldConfidence.missing ||
      existingVal == '待补录' ||
      existingVal.isEmpty) {
    return raw.copyWith(
      changeType: FieldChangeType.fill,
      existingValue: existingVal,
      existingFieldId: match.id,
    );
  }

  if (existingVal == raw.value) {
    return raw.copyWith(
      changeType: FieldChangeType.unchanged,
      existingValue: existingVal,
      existingFieldId: match.id,
    );
  }

  const conflictLabels = {'ECOG评分', '临床分期'};
  if (conflictLabels.contains(mappedLabel) &&
      match.confidence == FieldConfidence.conflict) {
    return raw.copyWith(
      changeType: FieldChangeType.conflict,
      existingValue: existingVal,
      existingFieldId: match.id,
    );
  }

  return raw.copyWith(
    changeType: FieldChangeType.update,
    existingValue: existingVal,
    existingFieldId: match.id,
  );
}

TimelineEventType _mapDocTypeToEventType(String docType) => switch (docType) {
      '病理报告' => TimelineEventType.pathology,
      '影像报告' => TimelineEventType.imaging,
      '实验室检查' => TimelineEventType.lab,
      '随访语音' => TimelineEventType.followUp,
      _ => TimelineEventType.diagnosis,
    };

DocumentModality _mapSourceToModality(UploadSource source) => switch (source) {
      UploadSource.camera => DocumentModality.image,
      UploadSource.pdf => DocumentModality.pdf,
      UploadSource.voice => DocumentModality.audio,
      UploadSource.gallery => DocumentModality.image,
    };

String _inferDiseaseGroup(String primarySite) {
  const mapping = <String, String>{
    '肺': '胸部肿瘤',
    '纵隔': '胸部肿瘤',
    '胸膜': '胸部肿瘤',
    '胃': '消化道肿瘤',
    '食管': '消化道肿瘤',
    '结直肠': '消化道肿瘤',
    '肝': '肝胆肿瘤',
    '胆': '肝胆肿瘤',
    '胰腺': '消化道肿瘤',
    '乳腺': '乳腺肿瘤',
    '卵巢': '妇科肿瘤',
    '宫颈': '妇科肿瘤',
    '子宫': '妇科肿瘤',
    '肾': '泌尿肿瘤',
    '膀胱': '泌尿肿瘤',
    '前列腺': '泌尿肿瘤',
    '头颈': '头颈肿瘤',
    '甲状腺': '头颈肿瘤',
    '皮肤': '皮肤肿瘤',
    '黑色素瘤': '皮肤肿瘤',
    '淋巴': '血液肿瘤',
  };
  return mapping[primarySite] ?? '其他肿瘤';
}
