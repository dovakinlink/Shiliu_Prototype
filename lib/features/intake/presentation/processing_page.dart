import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../domain/upload_job.dart';

final _processingJobProvider =
    FutureProvider.family<UploadJob?, String>((ref, jobId) async {
  ref.watch(mockAppStoreProvider);
  final jobs = await ref.read(uploadRepositoryProvider).getJobs();
  return jobs.where((j) => j.id == jobId).cast<UploadJob?>().firstOrNull;
});

class ProcessingPage extends ConsumerStatefulWidget {
  const ProcessingPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends ConsumerState<ProcessingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  int _currentStep = -1;
  bool _navigated = false;

  static const _steps = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.text_snippet_outlined,
      title: '文档识别',
      subtitle: 'OCR / ASR 文字提取',
    ),
    (
      icon: Icons.biotech_outlined,
      title: '医学实体抽取',
      subtitle: '识别诊断、药物、指标等实体',
    ),
    (
      icon: Icons.account_tree_outlined,
      title: '结构化字段映射',
      subtitle: '将实体映射到数据字典字段',
    ),
    (
      icon: Icons.verified_outlined,
      title: '置信度评估',
      subtitle: '评估每个字段的识别置信度',
    ),
    (
      icon: Icons.compare_arrows_rounded,
      title: '冲突检测',
      subtitle: '比对多源数据一致性',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    _progressController.forward();

    final stepInterval = _progressController.duration!.inMilliseconds ~/ _steps.length;

    for (int i = 0; i < _steps.length; i++) {
      await Future<void>.delayed(Duration(milliseconds: stepInterval));
      if (!mounted) return;
      setState(() => _currentStep = i);
    }

    ref.read(mockAppStoreProvider.notifier).advanceToNeedsReview(widget.jobId);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _navigated) return;
    _navigated = true;
    context.pushReplacement('/extraction/${widget.jobId}');
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobAsync = ref.watch(_processingJobProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 处理中'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Document info header
              jobAsync.maybeWhen(
                data: (job) {
                  if (job == null) return const SizedBox.shrink();
                  final sourceIcon = switch (job.source) {
                    UploadSource.camera => Icons.camera_alt_outlined,
                    UploadSource.pdf => Icons.description_outlined,
                    UploadSource.voice => Icons.mic_none_rounded,
                    UploadSource.gallery => Icons.photo_library_outlined,
                  };
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppPalette.surfaceVariantDark
                          : AppPalette.surfaceVariantLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppPalette.primary.withAlpha(isDark ? 25 : 18),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            sourceIcon,
                            size: 22,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                job.documentType,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${job.patientName} · ${job.source.label}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Progress bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '处理进度',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${(_progressController.value * 100).round()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppPalette.primary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? AppPalette.surfaceVariantDark
                              : AppPalette.surfaceVariantLight,
                          color: AppPalette.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // Steps list
              Text('处理步骤', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: ListView.separated(
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    final status = index < _currentStep
                        ? _StepStatus.done
                        : index == _currentStep
                            ? _StepStatus.active
                            : _StepStatus.waiting;
                    return _ProcessingStepTile(
                      icon: step.icon,
                      title: step.title,
                      subtitle: step.subtitle,
                      status: status,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { waiting, active, done }

class _ProcessingStepTile extends StatelessWidget {
  const _ProcessingStepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _StepStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (statusIcon, statusColor) = switch (status) {
      _StepStatus.done => (Icons.check_circle_rounded, AppPalette.success),
      _StepStatus.active => (Icons.autorenew_rounded, AppPalette.primary),
      _StepStatus.waiting => (
          Icons.radio_button_unchecked_rounded,
          isDark ? AppPalette.textTertiaryDark : AppPalette.textTertiaryLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: status == _StepStatus.active
            ? AppPalette.primary.withAlpha(isDark ? 12 : 8)
            : null,
        border: Border.all(
          color: status == _StepStatus.active
              ? AppPalette.primary.withAlpha(60)
              : (isDark ? AppPalette.borderDark : AppPalette.borderLight),
          width: 0.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(isDark ? 25 : 18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: status == _StepStatus.waiting
                        ? (isDark
                            ? AppPalette.textTertiaryDark
                            : AppPalette.textTertiaryLight)
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppPalette.textTertiaryDark
                        : AppPalette.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: status == _StepStatus.active
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : Icon(
                    statusIcon,
                    key: ValueKey(status),
                    size: 20,
                    color: statusColor,
                  ),
          ),
        ],
      ),
    );
  }
}
