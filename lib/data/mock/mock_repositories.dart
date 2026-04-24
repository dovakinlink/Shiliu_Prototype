import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../features/case_detail/application/case_repository.dart';
import '../../features/case_detail/domain/case_models.dart';
import '../../features/crf/application/crf_repository.dart';
import '../../features/crf/domain/crf_models.dart';
import '../../features/dashboard/application/dashboard_repository.dart';
import '../../features/dashboard/domain/dashboard_metric.dart';
import '../../features/inbox/domain/inbox_models.dart';
import '../../features/intake/application/upload_repository.dart';
import '../../features/intake/domain/upload_job.dart';
import '../../features/screening/application/screening_repository.dart';
import '../../features/screening/domain/screening_models.dart';
import '../../features/screening_hub/domain/screening_hub_models.dart';
import '../../features/search/application/search_repository.dart';
import '../../features/search/domain/search_models.dart';
import '../../features/tasks/application/task_repository.dart';
import '../../features/tasks/domain/task_models.dart';
import 'mock_app_store.dart';
import 'mock_crf_templates.dart';

final caseRepositoryProvider = Provider<CaseRepository>(MockCaseRepository.new);
final crfRepositoryProvider = Provider<CRFRepository>(MockCRFRepository.new);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  MockDashboardRepository.new,
);
final uploadRepositoryProvider = Provider<UploadRepository>(
  MockUploadRepository.new,
);
final screeningRepositoryProvider = Provider<ScreeningRepository>(
  MockScreeningRepository.new,
);
final searchRepositoryProvider = Provider<SearchRepository>(
  MockSearchRepository.new,
);
final taskRepositoryProvider = Provider<TaskRepository>(MockTaskRepository.new);

final inboxSnapshotProvider = FutureProvider<InboxSnapshot>((ref) async {
  ref.watch(mockAppStoreProvider);
  return MockInboxRepository(ref).getSnapshot();
});

final screeningHubSnapshotProvider = FutureProvider<ScreeningHubSnapshot>((
  ref,
) async {
  ref.watch(mockAppStoreProvider);
  return MockScreeningHubRepository(ref).getHubSnapshot();
});

class MockCaseRepository implements CaseRepository {
  const MockCaseRepository(this.ref);

  final Ref ref;

  @override
  Future<CaseDetail?> getCaseDetail(String caseId) async {
    final state = ref.read(mockAppStoreProvider);
    final bundle = state.cases
        .where((item) => item.detail.summary.id == caseId)
        .cast()
        .firstOrNull;
    return bundle?.detail;
  }

  @override
  Future<List<CaseSummary>> getCaseSummaries() async {
    final state = ref.read(mockAppStoreProvider);
    return state.cases
        .map((bundle) => bundle.detail.summary)
        .toList(growable: false);
  }

  @override
  Future<CaseSummary> createCase({
    required String patientName,
    required String sex,
    required int birthYear,
    required String primarySite,
    required String tumorType,
    String? diseaseProfileId,
    String? histology,
    String? stage,
  }) async {
    final bundle = ref
        .read(mockAppStoreProvider.notifier)
        .createCase(
          patientName: patientName,
          sex: sex,
          birthYear: birthYear,
          primarySite: primarySite,
          tumorType: tumorType,
          diseaseProfileId: diseaseProfileId,
          histology: histology,
          stage: stage,
        );
    return bundle.detail.summary;
  }
}

class MockCRFRepository implements CRFRepository {
  const MockCRFRepository(this.ref);

  final Ref ref;

  @override
  Future<DiseaseProfile?> getDiseaseProfile(String profileId) async {
    return mockDiseaseProfiles
        .where((profile) => profile.id == profileId)
        .firstOrNull;
  }

  @override
  Future<List<DiseaseProfile>> getDiseaseProfiles() async {
    return enabledMockDiseaseProfiles;
  }

  @override
  Future<CRFTemplate?> getTemplate(String templateId) async {
    return mockCrfTemplates
        .where((template) => template.id == templateId)
        .firstOrNull;
  }
}

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository(this.ref);

  final Ref ref;

  @override
  Future<DashboardSnapshot> getSnapshot() async {
    final state = ref.read(mockAppStoreProvider);
    final summaries = state.cases
        .map((bundle) => bundle.detail.summary)
        .toList(growable: false);
    final openTasks = state.cases
        .expand((bundle) => bundle.screening.tasks)
        .where((task) => !task.isCompleted)
        .toList(growable: false);
    final readyCount = summaries
        .where((summary) => summary.screeningStatus == ScreeningStatus.ready)
        .length;
    final progress = readyCount / summaries.length;

    return DashboardSnapshot(
      metrics: <DashboardMetric>[
        DashboardMetric(
          id: 'todo',
          label: '今日待处理',
          value: '${openTasks.length}',
          helper: '补录与冲突核对',
          deltaLabel:
              '${openTasks.where((task) => task.isBlocking).length} 个阻断项',
          isPositive: false,
        ),
        DashboardMetric(
          id: 'ready',
          label: '可初筛病例',
          value: '$readyCount',
          helper: '可直接进入 YABY',
          deltaLabel: '占比 ${(progress * 100).round()}%',
        ),
        DashboardMetric(
          id: 'liver',
          label: '肝功异常',
          value: '${summaries.where((summary) => summary.hasLiverRisk).length}',
          helper: '重点安全性复核',
          deltaLabel: 'PD-1 单药优先排查',
          isPositive: false,
        ),
        DashboardMetric(
          id: 'new',
          label: '近期新增',
          value: '2',
          helper: '近 7 日新增病例',
          deltaLabel: '含 1 例乳腺肿瘤',
        ),
      ],
      structuredProgress: progress,
      pendingTasks: openTasks.take(4).toList(growable: false),
      recentCases: summaries.take(6).toList(growable: false),
    );
  }
}

class MockUploadRepository implements UploadRepository {
  const MockUploadRepository(this.ref);

  final Ref ref;

  @override
  Future<void> advanceJob(String jobId) async {
    ref.read(mockAppStoreProvider.notifier).advanceUpload(jobId);
  }

  @override
  Future<UploadJob> createUpload({
    required String patientId,
    required String documentType,
    required UploadSource source,
    required String description,
  }) async {
    return ref
        .read(mockAppStoreProvider.notifier)
        .createUpload(
          patientId: patientId,
          documentType: documentType,
          source: source,
          description: description,
        );
  }

  @override
  Future<void> advanceToNeedsReview(String jobId) async {
    ref.read(mockAppStoreProvider.notifier).advanceToNeedsReview(jobId);
  }

  @override
  Future<List<UploadJob>> getJobs() async {
    final state = ref.read(mockAppStoreProvider);
    return state.uploads;
  }
}

class MockScreeningRepository implements ScreeningRepository {
  const MockScreeningRepository(this.ref);

  final Ref ref;

  @override
  Future<ScreeningSnapshot?> getSnapshot(String caseId) async {
    final state = ref.read(mockAppStoreProvider);
    final bundle = state.cases
        .where((item) => item.detail.summary.id == caseId)
        .cast()
        .firstOrNull;
    return bundle?.screening;
  }

  @override
  Future<void> supplementFields(
    String caseId,
    Map<String, String> values,
  ) async {
    ref.read(mockAppStoreProvider.notifier).supplementFields(caseId, values);
  }
}

class MockSearchRepository implements SearchRepository {
  const MockSearchRepository(this.ref);

  final Ref ref;

  @override
  Future<List<SearchResult>> searchCases(SearchFilter filter) async {
    final state = ref.read(mockAppStoreProvider);
    final bundles = state.cases
        .where((bundle) {
          final summary = bundle.detail.summary;
          final detail = bundle.detail;
          final drugClass = _drugClassOf(summary.currentRegimen);

          final matchesPrimarySite =
              filter.primarySite == null ||
              summary.primarySite == filter.primarySite;
          final matchesTumorType =
              filter.tumorType == null || summary.tumorType == filter.tumorType;
          final matchesStage =
              filter.stage == null || summary.stage == filter.stage;
          final matchesLine =
              filter.lineOfTherapy == null ||
              summary.lineOfTherapy == filter.lineOfTherapy;
          final matchesDrugClass =
              filter.drugClass == null || drugClass == filter.drugClass;
          final matchesLiverRisk =
              filter.hasLiverRisk == null ||
              summary.hasLiverRisk == filter.hasLiverRisk;
          final matchesEcog =
              filter.ecogMax == null || summary.ecog <= filter.ecogMax!;
          final matchesComorbidity =
              filter.comorbidity == null ||
              detail.comorbidities.contains(filter.comorbidity);
          final matchesScreening =
              filter.screeningStatusLabel == null ||
              summary.screeningStatus.label == filter.screeningStatusLabel;
          final matchesDiseaseProfile =
              filter.diseaseProfileId == null ||
              summary.diseaseProfileId == filter.diseaseProfileId;
          final matchesCrfTemplate =
              filter.crfTemplateId == null ||
              summary.crfTemplateId == filter.crfTemplateId;
          final matchesCrfConditions = filter.crfConditions.every(
            (condition) => _matchesCrfCondition(detail, condition),
          );

          return matchesPrimarySite &&
              matchesTumorType &&
              matchesStage &&
              matchesLine &&
              matchesDrugClass &&
              matchesLiverRisk &&
              matchesEcog &&
              matchesComorbidity &&
              matchesScreening &&
              matchesDiseaseProfile &&
              matchesCrfTemplate &&
              matchesCrfConditions;
        })
        .toList(growable: false);

    return bundles
        .map((bundle) {
          final summary = bundle.detail.summary;
          final reasons = <String>[
            if (filter.primarySite != null) '原发部位匹配 ${summary.primarySite}',
            if (filter.drugClass != null)
              '药物类别匹配 ${_drugClassOf(summary.currentRegimen)}',
            if (filter.hasLiverRisk == true && summary.hasLiverRisk) '存在肝功异常标签',
            if (filter.screeningStatusLabel != null)
              '筛查状态 ${summary.screeningStatus.label}',
            if (filter.comorbidity != null) '共病包含 ${filter.comorbidity}',
            if (filter.diseaseProfileId != null)
              '瘤种包 ${summary.diseaseGroupCode} ${summary.crfTemplateVersion}',
            ...filter.crfConditions.map((condition) {
              final value = bundle.detail.crfValues
                  .where((item) => item.fieldCode == condition.fieldCode)
                  .firstOrNull;
              return '专病：${condition.label}=${value?.value ?? condition.value}';
            }),
          ];
          return SearchResult(
            summary: summary,
            matchedReasons: reasons.isEmpty ? <String>['符合当前筛选条件'] : reasons,
          );
        })
        .toList(growable: false);
  }
}

class MockTaskRepository implements TaskRepository {
  const MockTaskRepository(this.ref);

  final Ref ref;

  @override
  Future<List<CompletenessTask>> getOpenTasks() async {
    final state = ref.read(mockAppStoreProvider);
    return state.cases
        .expand((bundle) => bundle.screening.tasks)
        .where((task) => !task.isCompleted)
        .toList(growable: false);
  }

  @override
  Future<CompletenessTask?> getTask(String taskId) async {
    final state = ref.read(mockAppStoreProvider);
    return state.cases
        .expand((bundle) => bundle.screening.tasks)
        .where((task) => task.id == taskId)
        .cast()
        .firstOrNull;
  }

  @override
  Future<void> resolveTask(String taskId, {String? resolvedValue}) async {
    ref
        .read(mockAppStoreProvider.notifier)
        .resolveTask(taskId, resolvedValue: resolvedValue);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class MockInboxRepository {
  const MockInboxRepository(this.ref);

  final Ref ref;

  Future<InboxSnapshot> getSnapshot() async {
    final state = ref.read(mockAppStoreProvider);
    final uploadItems = state.uploads
        .map((job) => InboxItem.upload(job))
        .toList(growable: false);
    final taskItems = state.cases
        .expand((bundle) => bundle.screening.tasks)
        .where((task) => !task.isCompleted)
        .map((task) => InboxItem.task(task))
        .toList(growable: false);

    final allItems = <InboxItem>[...uploadItems, ...taskItems];

    final uploadingCount = allItems
        .where((item) => item.matchesFilter(InboxFilter.uploading))
        .length;
    final pendingCount = allItems
        .where((item) => item.matchesFilter(InboxFilter.pending))
        .length;
    final conflictCount = allItems
        .where((item) => item.matchesFilter(InboxFilter.conflict))
        .length;

    return InboxSnapshot(
      items: allItems,
      totalCount: allItems.length,
      uploadingCount: uploadingCount,
      pendingCount: pendingCount,
      conflictCount: conflictCount,
    );
  }
}

class MockScreeningHubRepository {
  const MockScreeningHubRepository(this.ref);

  final Ref ref;

  Future<ScreeningHubSnapshot> getHubSnapshot() async {
    final state = ref.read(mockAppStoreProvider);
    final bundles = state.cases;

    final readyCount = bundles
        .where((b) => b.detail.summary.screeningStatus == ScreeningStatus.ready)
        .length;
    final partialCount = bundles
        .where(
          (b) => b.detail.summary.screeningStatus == ScreeningStatus.partial,
        )
        .length;
    final notReadyCount = bundles
        .where(
          (b) => b.detail.summary.screeningStatus == ScreeningStatus.notReady,
        )
        .length;
    final totalCases = bundles.length;
    final overallProgress = totalCases == 0 ? 0.0 : readyCount / totalCases;

    final projects = bundles
        .map((bundle) {
          final summary = bundle.detail.summary;
          final screening = bundle.screening;
          return ScreeningProject(
            projectTitle: screening.projectTitle,
            caseId: summary.id,
            patientName: summary.patientName,
            patientCode: summary.patientCode,
            status: summary.screeningStatus,
            keyFacts: screening.keyFacts,
            blockingCount: screening.blockingFields.length,
            reminderCount: screening.reminderFields.length,
          );
        })
        .toList(growable: false);

    final blockingMap = <String, List<String>>{};
    for (final bundle in bundles) {
      for (final field in bundle.screening.blockingFields) {
        blockingMap.putIfAbsent(field, () => <String>[]);
        blockingMap[field]!.add(bundle.detail.summary.id);
      }
    }
    final topBlockingFields =
        blockingMap.entries
            .map(
              (entry) => BlockingFieldSummary(
                fieldName: entry.key,
                caseCount: entry.value.length,
                caseIds: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.caseCount.compareTo(a.caseCount));

    return ScreeningHubSnapshot(
      totalCases: totalCases,
      readyCount: readyCount,
      partialCount: partialCount,
      notReadyCount: notReadyCount,
      overallProgress: overallProgress,
      projects: projects,
      topBlockingFields: topBlockingFields,
    );
  }
}

String _drugClassOf(String regimen) {
  if (regimen.contains('PD-1')) {
    return 'PD-1';
  }
  if (regimen.contains('ADC')) {
    return 'ADC';
  }
  if (regimen.contains('VEGF')) {
    return '抗VEGF';
  }
  return '化疗';
}

bool _matchesCrfCondition(CaseDetail detail, CRFFilterCondition condition) {
  if (detail.crfTemplate.id != condition.templateId) return false;
  final value = detail.crfValues
      .where((item) => item.fieldCode == condition.fieldCode)
      .firstOrNull;
  if (value == null || !value.isComplete) return false;

  final actual = value.value;
  final expected = condition.value;
  switch (condition.operator) {
    case CRFFilterOperator.equals:
      return actual == expected;
    case CRFFilterOperator.contains:
      return actual.contains(expected);
    case CRFFilterOperator.gte:
      final actualNumber = double.tryParse(actual.replaceAll('%', ''));
      final expectedNumber = double.tryParse(expected.replaceAll('%', ''));
      return actualNumber != null &&
          expectedNumber != null &&
          actualNumber >= expectedNumber;
    case CRFFilterOperator.lte:
      final actualNumber = double.tryParse(actual.replaceAll('%', ''));
      final expectedNumber = double.tryParse(expected.replaceAll('%', ''));
      return actualNumber != null &&
          expectedNumber != null &&
          actualNumber <= expectedNumber;
  }
}
