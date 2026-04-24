import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/case_picker_sheet.dart';
import '../../../shared/widgets/create_case_sheet.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../case_detail/domain/case_models.dart';
import '../domain/upload_job.dart';

final intakeJobsProvider = FutureProvider<List<UploadJob>>((ref) async {
  ref.watch(mockAppStoreProvider);
  return ref.read(uploadRepositoryProvider).getJobs();
});

final intakeCaseOptionsProvider = FutureProvider<List<CaseSummary>>((ref) async {
  ref.watch(mockAppStoreProvider);
  return ref.read(caseRepositoryProvider).getCaseSummaries();
});

class IntakePage extends ConsumerWidget {
  const IntakePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(intakeJobsProvider);
    final cases = ref.watch(intakeCaseOptionsProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xxl,
          AppSpacing.page,
          AppSpacing.xxxxl,
        ),
        children: <Widget>[
          Text('多模态病例采集', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '模拟资料进入系统，推进 AI 处理、结构化摘要与人工确认',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: UploadSource.values
                    .map(
                      (source) => SizedBox(
                        width: cardWidth,
                        child: _SourceCard(
                          source: source,
                          onTap: cases.maybeWhen(
                            data: (caseOptions) => () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => UploadComposerSheet(
                                source: source,
                                cases: caseOptions,
                              ),
                            ),
                            orElse: () => null,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('上传任务', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          jobs.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.cloud_upload_outlined,
                  title: '暂无上传任务',
                  description: '点击上方采集方式创建新任务',
                );
              }
              return Column(
                children: items
                    .map(
                      (job) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _UploadJobCard(job: job),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, _) => AppErrorState(message: '$error'),
            loading: () => const SkeletonBlock(height: 120),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.onTap,
  });

  final UploadSource source;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final icon = switch (source) {
      UploadSource.camera => Icons.camera_alt_outlined,
      UploadSource.pdf => Icons.description_outlined,
      UploadSource.voice => Icons.mic_none_rounded,
      UploadSource.gallery => Icons.photo_library_outlined,
    };

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppPalette.primary.withAlpha(25)
                      : AppPalette.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppPalette.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(source.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '创建上传任务',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadJobCard extends ConsumerWidget {
  const _UploadJobCard({required this.job});

  final UploadJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tone = switch (job.stage) {
      UploadJobStage.queued => StatusTone.neutral,
      UploadJobStage.processing => StatusTone.pending,
      UploadJobStage.extracted => StatusTone.warning,
      UploadJobStage.needsReview => StatusTone.conflict,
    };

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(job.documentType, style: theme.textTheme.titleMedium),
              ),
              StatusBadge(label: job.stage.label, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${job.patientName} · ${job.source.label} · ${job.createdAtLabel}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(job.description, style: theme.textTheme.bodyMedium),
          if (job.extractedHighlights.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '结构化摘要：${job.extractedHighlights.join(' / ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.primary,
              ),
            ),
          ],
          if (job.pendingReviewFields.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '待人工确认：${job.pendingReviewFields.join('、')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.warning,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                if (job.stage == UploadJobStage.needsReview) {
                  context.push('/case/${job.patientId}');
                  return;
                }
                await ref.read(uploadRepositoryProvider).advanceJob(job.id);
              },
              child: Text(
                job.stage == UploadJobStage.needsReview ? '查看病例' : '推进下一步',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadComposerSheet extends ConsumerStatefulWidget {
  const UploadComposerSheet({
    required this.source,
    required this.cases,
    this.navigateToProcessing = false,
    super.key,
  });

  final UploadSource source;
  final List<CaseSummary> cases;
  final bool navigateToProcessing;

  @override
  ConsumerState<UploadComposerSheet> createState() => _UploadComposerSheetState();
}

class _UploadComposerSheetState extends ConsumerState<UploadComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _patientId;
  CaseSummary? _selectedCase;
  String _documentType = '病理报告';
  late final List<CaseSummary> _cases = List<CaseSummary>.of(widget.cases);
  String? _caseValidationError;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openCreateCase() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await showModalBottomSheet<CaseSummary>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateCaseSheet(),
    );
  }

  Future<void> _openCasePicker() async {
    final selected = await showModalBottomSheet<CaseSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CasePickerSheet(
        cases: _cases,
        selectedId: _patientId,
        onCreateCase: _openCreateCase,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCase = selected;
        _patientId = selected.id;
        _caseValidationError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + insets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.source.label, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _openCasePicker,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '选择病例',
                  errorText: _caseValidationError,
                  suffixIcon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                ),
                isEmpty: _selectedCase == null,
                child: _selectedCase == null
                    ? null
                    : Row(
                        children: <Widget>[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppPalette.primary.withAlpha(18)
                                  : AppPalette.primarySurface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedCase!.patientName.isNotEmpty
                                  ? _selectedCase!.patientName[0]
                                  : '?',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${_selectedCase!.patientName} · ${_selectedCase!.patientCode}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_selectedCase!.tumorType} · ${_selectedCase!.stage}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppPalette.textSecondaryDark
                                        : AppPalette.textSecondaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: const InputDecoration(labelText: '文档类型'),
              items: const <String>['病理报告', '影像报告', '随访语音', '实验室检查']
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => _documentType = value ?? _documentType),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '补充说明',
                hintText: '例如：外院新增病理、门诊随访语音等',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '请输入补充说明' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final formValid = _formKey.currentState!.validate();
                  if (_patientId == null) {
                    setState(() => _caseValidationError = '请选择病例');
                  }
                  if (!formValid || _patientId == null) {
                    return;
                  }
                  final navigator = Navigator.of(context);
                  final job =
                      await ref.read(uploadRepositoryProvider).createUpload(
                            patientId: _patientId!,
                            documentType: _documentType,
                            source: widget.source,
                            description: _descriptionController.text.trim(),
                          );
                  if (!mounted) {
                    return;
                  }
                  if (widget.navigateToProcessing) {
                    navigator.pop(job.id);
                  } else {
                    navigator.pop();
                  }
                },
                child: const Text('创建上传任务'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
