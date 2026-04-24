import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiliu_app_prototype/core/constants/app_enums.dart';
import 'package:shiliu_app_prototype/data/mock/mock_app_store.dart';
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
        const SearchFilter(drugClass: 'PD-1', hasLiverRisk: true),
      );

      expect(results, isNotEmpty);
      expect(
        results.every(
          (item) =>
              item.summary.currentRegimen.contains('PD-1') &&
              item.summary.hasLiverRisk,
        ),
        isTrue,
      );
    });

    test(
      'crf repository exposes active templates and cases bind a template',
      () async {
        final crfRepository = container.read(crfRepositoryProvider);
        final caseRepository = container.read(caseRepositoryProvider);

        final profiles = await crfRepository.getDiseaseProfiles();
        expect(profiles, isNotEmpty);

        final guTemplate = await crfRepository.getTemplate('gu-crf-v2026-03');
        expect(guTemplate, isNotNull);
        expect(guTemplate!.fieldCount, greaterThan(10));

        final detail = await caseRepository.getCaseDetail('case-005');
        expect(detail, isNotNull);
        expect(detail!.summary.diseaseGroupCode, 'GU');
        expect(detail.crfTemplate.id, 'gu-crf-v2026-03');
        expect(detail.summary.crfCompletionRate, greaterThan(0));
      },
    );

    test('specialty search can match GU CRF conditions', () async {
      final repository = container.read(searchRepositoryProvider);

      final results = await repository.searchCases(
        const SearchFilter(
          diseaseProfileId: 'gu-bladder',
          crfTemplateId: 'gu-crf-v2026-03',
          crfConditions: <CRFFilterCondition>[
            CRFFilterCondition(
              templateId: 'gu-crf-v2026-03',
              fieldCode: 'gu.pathology.pt',
              label: 'pT',
              operator: CRFFilterOperator.equals,
              value: 'pT2',
            ),
            CRFFilterCondition(
              templateId: 'gu-crf-v2026-03',
              fieldCode: 'gu.admission.urinary_obstruction',
              label: '尿路梗阻程度',
              operator: CRFFilterOperator.equals,
              value: '中度',
            ),
          ],
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.summary.id, 'case-005');
      expect(
        results.single.matchedReasons.any((reason) => reason.contains('专病')),
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

    test('upload review writes CRF values and canonical metadata', () async {
      final uploadRepository = container.read(uploadRepositoryProvider);
      final caseRepository = container.read(caseRepositoryProvider);
      final store = container.read(mockAppStoreProvider.notifier);

      final job = await uploadRepository.createUpload(
        patientId: 'case-005',
        documentType: '病理报告',
        source: UploadSource.pdf,
        description: '泌尿系病理报告测试上传',
      );

      await uploadRepository.advanceToNeedsReview(job.id);
      final jobs = await uploadRepository.getJobs();
      final reviewJob = jobs.firstWhere((item) => item.id == job.id);

      expect(
        reviewJob.extractionDetails.any(
          (detail) => detail.fieldCode == 'gu.pathology.pt',
        ),
        isTrue,
      );
      expect(
        reviewJob.extractionDetails.any(
          (detail) => detail.canonicalImpact != null,
        ),
        isTrue,
      );

      store.confirmUploadReview(job.id);
      final detail = await caseRepository.getCaseDetail('case-005');
      final pt = detail!.crfValues.firstWhere(
        (value) => value.fieldCode == 'gu.pathology.pt',
      );

      expect(pt.value, 'pT2');
      expect(pt.status, CRFValueStatus.filled);
      expect(detail.summary.crfCompletionRate, greaterThan(0.75));
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

    test(
      'conflict tasks can be resolved and refresh screening state',
      () async {
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
      },
    );
  });
}
