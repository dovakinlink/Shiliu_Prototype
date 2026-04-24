import 'package:flutter/material.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_crf_templates.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../case_detail/domain/case_models.dart';
import '../domain/crf_models.dart';

class CrfTemplateSummaryCard extends StatelessWidget {
  const CrfTemplateSummaryCard({
    required this.detail,
    this.onViewCrf,
    super.key,
  });

  final CaseDetail detail;
  final VoidCallback? onViewCrf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = detail.crfTemplate;
    final completeness = calculateCrfCompleteness(template, detail.crfValues);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  detail.diseaseProfile.groupCode,
                  style: const TextStyle(
                    color: AppPalette.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(template.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${detail.diseaseProfile.tumorName} · ${template.version} · ${template.status.label}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onViewCrf != null)
                IconButton(
                  onPressed: onViewCrf,
                  icon: const Icon(Icons.view_list_outlined, size: 20),
                  tooltip: '查看专病 CRF',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: completeness.rate,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              StatusBadge(label: 'CRF ${(completeness.rate * 100).round()}%'),
              StatusBadge(label: '${template.fieldCount} 字段'),
              StatusBadge(
                label: '${completeness.blockingMissingCount} 阻断缺失',
                tone: completeness.blockingMissingCount > 0
                    ? StatusTone.error
                    : StatusTone.success,
              ),
              if (template.governanceFieldCount > 0)
                StatusBadge(
                  label: '${template.governanceFieldCount} 待治理',
                  tone: StatusTone.pending,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CrfSectionList extends StatefulWidget {
  const CrfSectionList({required this.detail, super.key});

  final CaseDetail detail;

  @override
  State<CrfSectionList> createState() => _CrfSectionListState();
}

class _CrfSectionListState extends State<CrfSectionList> {
  final _queryController = TextEditingController();
  _CrfViewFilter _filter = _CrfViewFilter.all;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final theme = Theme.of(context);
    final valuesByCode = <String, CaseCRFValue>{
      for (final value in detail.crfValues) value.fieldCode: value,
    };
    final query = _queryController.text.trim().toLowerCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxxxl,
      ),
      children: <Widget>[
        CrfTemplateSummaryCard(detail: detail),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _queryController,
          decoration: const InputDecoration(
            labelText: '搜索字段',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _CrfViewFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...detail.crfTemplate.sections.map((section) {
          final fields = section.allFields
              .where((field) {
                final value = valuesByCode[field.fieldCode];
                final text =
                    '${field.label} ${field.displayPath} ${value?.value ?? ''}'
                        .toLowerCase();
                return (query.isEmpty || text.contains(query)) &&
                    _filter.matches(field, value);
              })
              .toList(growable: false);

          if (fields.isEmpty) return const SizedBox.shrink();
          final completed = section.allFields.where((field) {
            final value = valuesByCode[field.fieldCode];
            return value?.isComplete == true;
          }).length;
          final sectionTotal = section.allFields.length;
          final completion = sectionTotal == 0 ? 0 : completed / sectionTotal;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CollapsibleSection(
              title: section.title,
              icon: Icons.account_tree_outlined,
              initiallyExpanded: section == detail.crfTemplate.sections.first,
              trailing: StatusBadge(
                label: '${(completion * 100).round()}%',
                tone: completion >= 0.8
                    ? StatusTone.success
                    : StatusTone.warning,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: completion.toDouble(),
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (int i = 0; i < fields.length; i++) ...<Widget>[
                    CrfFieldTile(
                      field: fields[i],
                      value: valuesByCode[fields[i].fieldCode],
                      mapping: findFieldMapping(
                        detail.crfTemplate,
                        fields[i].fieldCode,
                      ),
                    ),
                    if (i < fields.length - 1)
                      const Divider(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          );
        }),
        if (detail.crfTemplate.sections.every(
          (section) => section.allFields.every((field) {
            final value = valuesByCode[field.fieldCode];
            final text =
                '${field.label} ${field.displayPath} ${value?.value ?? ''}'
                    .toLowerCase();
            return !(query.isEmpty || text.contains(query)) ||
                !_filter.matches(field, value);
          }),
        ))
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: '没有匹配字段',
            description: '调整搜索词或字段状态筛选',
          ),
      ],
    );
  }
}

class CrfFieldTile extends StatelessWidget {
  const CrfFieldTile({
    required this.field,
    required this.value,
    this.mapping,
    super.key,
  });

  final CRFField field;
  final CaseCRFValue? value;
  final FieldMapping? mapping;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = value?.status ?? CRFValueStatus.missing;
    final statusTone = switch (status) {
      CRFValueStatus.filled => StatusTone.success,
      CRFValueStatus.notApplicable => StatusTone.neutral,
      CRFValueStatus.conflict => StatusTone.conflict,
      CRFValueStatus.missing => StatusTone.error,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(field.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(field.displayPath, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            StatusBadge(label: status.label, tone: statusTone),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value?.value ?? '待补录',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: status == CRFValueStatus.missing
                ? null
                : FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            StatusBadge(label: field.fieldCode),
            StatusBadge(label: field.dataType.label),
            StatusBadge(
              label: field.requiredLevel.label,
              tone: switch (field.requiredLevel) {
                RequiredLevel.blocking => StatusTone.error,
                RequiredLevel.recommended => StatusTone.warning,
                RequiredLevel.optional => StatusTone.neutral,
              },
            ),
            if (field.searchable) const StatusBadge(label: '可搜索'),
            if (field.needsGovernance)
              const StatusBadge(label: '待治理', tone: StatusTone.pending),
            if (value != null) StatusBadge(label: value!.confidence.label),
          ],
        ),
        if (mapping != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(
                Icons.sync_alt_rounded,
                size: 14,
                color: AppPalette.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '主干回写：${mapping!.displayImpact}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _CrfViewFilter { all, missing, conflict, searchable }

extension on _CrfViewFilter {
  String get label => switch (this) {
    _CrfViewFilter.all => '全部',
    _CrfViewFilter.missing => '缺失',
    _CrfViewFilter.conflict => '冲突',
    _CrfViewFilter.searchable => '可搜索',
  };

  bool matches(CRFField field, CaseCRFValue? value) => switch (this) {
    _CrfViewFilter.all => true,
    _CrfViewFilter.missing =>
      value == null || value.status == CRFValueStatus.missing,
    _CrfViewFilter.conflict => value?.status == CRFValueStatus.conflict,
    _CrfViewFilter.searchable => field.searchable,
  };
}
