import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_crf_templates.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_filter_chip.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/patient_summary_card.dart';
import '../domain/search_models.dart';

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilter>(
      SearchFilterNotifier.new,
    );

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  ref.watch(mockAppStoreProvider);
  final filter = ref.watch(searchFilterProvider);
  return ref.read(searchRepositoryProvider).searchCases(filter);
});

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  static const primarySites = <String>[
    '肺',
    '胃',
    '食管',
    '乳腺',
    '卵巢',
    '结直肠',
    '肝',
    '纵隔',
  ];
  static const tumorTypes = <String>['非小细胞肺癌', '胃癌', '食管鳞癌', 'HER2 低表达乳腺癌'];
  static const stages = <String>['IIIB期', 'III期', 'IV期'];
  static const drugClasses = <String>['PD-1', 'ADC', '抗VEGF', '化疗'];
  static const comorbidities = <String>['2 型糖尿病', '高血压', 'COPD', '乙肝携带'];
  static const screeningStatuses = <String>['可初筛', '部分可初筛', '不可初筛'];
  static const crfDemoConditions = <CRFFilterCondition>[
    CRFFilterCondition(
      templateId: 'gu-crf-v2026-03',
      fieldCode: 'gu.pathology.pt',
      label: 'pT',
      operator: CRFFilterOperator.equals,
      value: 'pT2',
    ),
    CRFFilterCondition(
      templateId: 'gu-crf-v2026-03',
      fieldCode: 'gu.pathology.pd_l1',
      label: 'PD-L1',
      operator: CRFFilterOperator.equals,
      value: '高表达',
    ),
    CRFFilterCondition(
      templateId: 'gu-crf-v2026-03',
      fieldCode: 'gu.admission.urinary_obstruction',
      label: '尿路梗阻程度',
      operator: CRFFilterOperator.equals,
      value: '中度',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final results = ref.watch(searchResultsProvider);
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
          Text('组合检索', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('多维度筛选条件构建目标队列', style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sectionGap),

          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppPalette.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('筛选条件', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _FilterGroup(
                  title: '原发部位',
                  children: primarySites
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.primarySite == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    primarySite: selected ? item : null,
                                    clearPrimarySite: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '瘤种',
                  children: tumorTypes
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.tumorType == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    tumorType: selected ? item : null,
                                    clearTumorType: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '瘤种包',
                  children: enabledMockDiseaseProfiles
                      .map(
                        (profile) => AppFilterChip(
                          label: '${profile.groupCode} ${profile.tumorName}',
                          selected: filter.diseaseProfileId == profile.id,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    diseaseProfileId: selected
                                        ? profile.id
                                        : null,
                                    crfTemplateId: selected
                                        ? profile.defaultTemplateId
                                        : null,
                                    clearDiseaseProfile: !selected,
                                    clearCrfTemplate: !selected,
                                    clearCrfConditions: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '专病筛选',
                  children: crfDemoConditions
                      .map((condition) {
                        final selected = filter.crfConditions.any(
                          (item) =>
                              item.fieldCode == condition.fieldCode &&
                              item.value == condition.value,
                        );
                        return AppFilterChip(
                          label: condition.displayLabel,
                          selected: selected,
                          onSelected: (value) {
                            final next = value
                                ? <CRFFilterCondition>[
                                    ...filter.crfConditions,
                                    condition,
                                  ]
                                : filter.crfConditions
                                      .where(
                                        (item) =>
                                            item.fieldCode !=
                                            condition.fieldCode,
                                      )
                                      .toList(growable: false);
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    diseaseProfileId: 'gu-bladder',
                                    crfTemplateId: condition.templateId,
                                    crfConditions: next,
                                  ),
                                );
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '分期',
                  children: stages
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.stage == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    stage: selected ? item : null,
                                    clearStage: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '药物类别',
                  children: drugClasses
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.drugClass == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    drugClass: selected ? item : null,
                                    clearDrugClass: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '共病',
                  children: comorbidities
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.comorbidity == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    comorbidity: selected ? item : null,
                                    clearComorbidity: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '筛查状态',
                  children: screeningStatuses
                      .map(
                        (item) => AppFilterChip(
                          label: item,
                          selected: filter.screeningStatusLabel == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    screeningStatusLabel: selected
                                        ? item
                                        : null,
                                    clearScreeningStatus: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                _FilterGroup(
                  title: '治疗线数',
                  children: <int>[1, 2, 3]
                      .map(
                        (item) => AppFilterChip(
                          label: '$item 线',
                          selected: filter.lineOfTherapy == item,
                          onSelected: (selected) {
                            ref
                                .read(searchFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(
                                    lineOfTherapy: selected ? item : null,
                                    clearLineOfTherapy: !selected,
                                  ),
                                );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: filter.hasLiverRisk ?? false,
                        title: Text('肝功异常', style: theme.textTheme.bodyMedium),
                        onChanged: (value) {
                          ref
                              .read(searchFilterProvider.notifier)
                              .setFilter(filter.copyWith(hasLiverRisk: value));
                        },
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: filter.ecogMax,
                        decoration: const InputDecoration(labelText: 'ECOG ≤'),
                        items: const <int>[0, 1, 2, 3]
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item,
                                child: Text('$item'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          ref
                              .read(searchFilterProvider.notifier)
                              .setFilter(
                                filter.copyWith(
                                  ecogMax: value,
                                  clearEcogMax: value == null,
                                ),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: ref.read(searchFilterProvider.notifier).clear,
                    child: const Text('清空筛选'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('检索结果', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          results.when(
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: '没有符合条件的病例',
                  description: '试试放宽筛选条件',
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SearchResultCard(item: item),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, _) => AppErrorState(message: '$error'),
            loading: () => const SkeletonBlock(height: 160),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.item});

  final SearchResult item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PatientSummaryCard(
            summary: item.summary,
            onTap: () => context.push('/case/${item.summary.id}'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '命中原因：${item.matchedReasons.join('；')}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: () => context.push('/case/${item.summary.id}'),
                child: const Text('查看病例'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: () => context.push('/screening/${item.summary.id}'),
                child: const Text('查看筛查'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() =>
      const SearchFilter(drugClass: 'PD-1', hasLiverRisk: true);

  void setFilter(SearchFilter filter) {
    state = filter;
  }

  void clear() {
    state = const SearchFilter();
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: children,
          ),
        ],
      ),
    );
  }
}
