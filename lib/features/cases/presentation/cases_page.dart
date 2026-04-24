import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_crf_templates.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_filter_chip.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/create_case_sheet.dart';
import '../../../shared/widgets/patient_summary_card.dart';
import '../../search/domain/search_models.dart';
import '../../search/presentation/search_page.dart';

final _searchQueryProvider = NotifierProvider<_SearchQueryNotifier, String>(
  _SearchQueryNotifier.new,
);

final _filterExpandedProvider = NotifierProvider<_FilterExpandedNotifier, bool>(
  _FilterExpandedNotifier.new,
);

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

class _FilterExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final _casesResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  ref.watch(mockAppStoreProvider);
  final filter = ref.watch(searchFilterProvider);
  final query = ref.watch(_searchQueryProvider).trim().toLowerCase();
  final results = await ref.read(searchRepositoryProvider).searchCases(filter);
  if (query.isEmpty) return results;
  return results
      .where(
        (r) =>
            r.summary.patientName.toLowerCase().contains(query) ||
            r.summary.patientCode.toLowerCase().contains(query),
      )
      .toList(growable: false);
});

class CasesPage extends ConsumerStatefulWidget {
  const CasesPage({super.key});

  @override
  ConsumerState<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends ConsumerState<CasesPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_casesResultsProvider);
    final filter = ref.watch(searchFilterProvider);
    final isExpanded = ref.watch(_filterExpandedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => CreateCaseSheet(
            onCreated: (summary) {
              context.push('/case/${summary.id}');
            },
          ),
        ),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('新建病例'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xxl,
                  AppSpacing.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('病例库', style: theme.textTheme.headlineMedium),
                        const Spacer(),
                        results.whenOrNull(
                              data: (items) => Text(
                                '${items.length} 例',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppPalette.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ) ??
                            const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) =>
                          ref.read(_searchQueryProvider.notifier).set(value),
                      onClear: () {
                        _searchController.clear();
                        ref.read(_searchQueryProvider.notifier).set('');
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (filter.hasActiveFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  child: _ActiveFilterChips(
                    filter: filter,
                    onClear: ref.read(searchFilterProvider.notifier).clear,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  0,
                ),
                child: _FilterToggleButton(
                  isExpanded: isExpanded,
                  hasActiveFilters: filter.hasActiveFilters,
                  onTap: () =>
                      ref.read(_filterExpandedProvider.notifier).toggle(),
                ),
              ),
            ),

            if (isExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  child: const _FilterPanel(),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            results.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: '没有符合条件的病例',
                        description: '试试放宽筛选条件或修改搜索词',
                      ),
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xxxxl,
                    ),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < items.length; i++) ...<Widget>[
                            PatientSummaryCard(
                              summary: items[i].summary,
                              onTap: () =>
                                  context.push('/case/${items[i].summary.id}'),
                            ),
                            if (i < items.length - 1)
                              const Divider(height: 1, indent: 58),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
              error: (error, _) =>
                  SliverFillRemaining(child: AppErrorState(message: '$error')),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.page),
                  child: SkeletonBlock(height: 160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '搜索患者姓名或编号',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.onClear});

  final SearchFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.primarySite != null) filter.primarySite!,
      if (filter.tumorType != null) filter.tumorType!,
      if (filter.stage != null) filter.stage!,
      if (filter.drugClass != null) filter.drugClass!,
      if (filter.comorbidity != null) filter.comorbidity!,
      if (filter.screeningStatusLabel != null) filter.screeningStatusLabel!,
      if (filter.diseaseProfileId != null)
        mockDiseaseProfileById(filter.diseaseProfileId!).displayName,
      ...filter.crfConditions.map((condition) => condition.displayLabel),
      if (filter.lineOfTherapy != null) '${filter.lineOfTherapy} 线',
      if (filter.hasLiverRisk == true) '肝功异常',
      if (filter.ecogMax != null) 'ECOG ≤ ${filter.ecogMax}',
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        ...labels.map(
          (label) => Chip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        ActionChip(
          label: const Text('清空', style: TextStyle(fontSize: 12)),
          onPressed: onClear,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.isExpanded,
    required this.hasActiveFilters,
    required this.onTap,
  });

  final bool isExpanded;
  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.tune_rounded,
            size: 16,
            color: hasActiveFilters
                ? AppPalette.primary
                : theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isExpanded ? '收起筛选' : '展开筛选',
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasActiveFilters ? AppPalette.primary : null,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,

        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FilterGroup(
            title: '原发部位',
            children: SearchPage.primarySites
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
            children: SearchPage.tumorTypes
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
                              diseaseProfileId: selected ? profile.id : null,
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
            children: SearchPage.crfDemoConditions
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
                                      item.fieldCode != condition.fieldCode,
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
            children: SearchPage.stages
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
            children: SearchPage.drugClasses
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
            children: SearchPage.comorbidities
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
            children: SearchPage.screeningStatuses
                .map(
                  (item) => AppFilterChip(
                    label: item,
                    selected: filter.screeningStatusLabel == item,
                    onSelected: (selected) {
                      ref
                          .read(searchFilterProvider.notifier)
                          .setFilter(
                            filter.copyWith(
                              screeningStatusLabel: selected ? item : null,
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
    );
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
