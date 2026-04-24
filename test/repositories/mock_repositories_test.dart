import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiliu_app_prototype/core/constants/app_enums.dart';
import 'package:shiliu_app_prototype/data/mock/mock_repositories.dart';
import 'package:shiliu_app_prototype/features/search/domain/search_models.dart';

void main() {
  group('Mock repositories', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('search can build the PD-1 plus liver-risk cohort', () async {
      final repository = container.read(searchRepositoryProvider);
      final results = await repository.searchCases(
        const SearchFilter(
          drugClass: 'PD-1',
          hasLiverRisk: true,
        ),
      );

      expect(results, isNotEmpty);
      expect(
        results.every((item) =>
            item.summary.currentRegimen.contains('PD-1') &&
            item.summary.hasLiverRisk),
        isTrue,
      );
    });

    test('upload jobs move through the local state machine', () async {
      final repository = container.read(uploadRepositoryProvider);
      final job = await repository.createUpload(
        patientId: 'case-001',
        documentType: '病理报告',
        source: UploadSource.pdf,
        description: '测试上传',
      );

      var jobs = await repository.getJobs();
      expect(jobs.first.stage, UploadJobStage.queued);

      await repository.advanceJob(job.id);
      jobs = await repository.getJobs();
      expect(jobs.first.stage, UploadJobStage.processing);

      await repository.advanceJob(job.id);
      jobs = await repository.getJobs();
      expect(jobs.first.stage, UploadJobStage.extracted);
      expect(jobs.first.extractedHighlights, isNotEmpty);

      await repository.advanceJob(job.id);
      jobs = await repository.getJobs();
      expect(jobs.first.stage, UploadJobStage.needsReview);
      expect(jobs.first.pendingReviewFields, isNotEmpty);
    });

    test('screening supplement can move a blocked case to ready', () async {
      final screeningRepository = container.read(screeningRepositoryProvider);
      final caseRepository = container.read(caseRepositoryProvider);

      final before = await screeningRepository.getSnapshot('case-003');
      expect(before, isNotNull);
      expect(before!.status, ScreeningStatus.notReady);

      await screeningRepository.supplementFields('case-003', <String, String>{
        'ECOG评分': '1',
        '当前方案': 'PD-1 单药维持',
        '关键分子标志物': 'PD-L1 TPS 70%',
      });

      final after = await screeningRepository.getSnapshot('case-003');
      final detail = await caseRepository.getCaseDetail('case-003');

      expect(after, isNotNull);
      expect(after!.status, ScreeningStatus.ready);
      expect(detail, isNotNull);
      expect(detail!.summary.currentRegimen, 'PD-1 单药维持');
      expect(detail.summary.ecog, 1);
    });

    test('conflict tasks can be resolved and refresh screening state', () async {
      final taskRepository = container.read(taskRepositoryProvider);
      final screeningRepository = container.read(screeningRepositoryProvider);

      final before = await screeningRepository.getSnapshot('case-001');
      expect(before, isNotNull);
      expect(before!.status, ScreeningStatus.partial);

      final task = await taskRepository.getTask('case-001-task-conflict');
      expect(task, isNotNull);

      await taskRepository.resolveTask(task!.id);

      final after = await screeningRepository.getSnapshot('case-001');
      expect(after, isNotNull);
      expect(after!.status, ScreeningStatus.ready);
    });
  });
}
