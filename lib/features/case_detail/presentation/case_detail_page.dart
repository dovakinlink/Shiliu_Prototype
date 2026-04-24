import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_app_store.dart';
import '../../../data/mock/mock_repositories.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/patient_summary_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/timeline_event_tile.dart';
import '../domain/case_models.dart';

final caseDetailProvider =
    FutureProvider.family<CaseDetail?, String>((ref, caseId) async {
  ref.watch(mockAppStoreProvider);
  return ref.read(caseRepositoryProvider).getCaseDetail(caseId);
});

class CaseDetailPage extends ConsumerStatefulWidget {
  const CaseDetailPage({
    required this.caseId,
    super.key,
  });

  final String caseId;

  @override
  ConsumerState<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends ConsumerState<CaseDetailPage> {
  String? selectedEventId;
  String? selectedFieldId;
  String? selectedEvidenceId;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(caseDetailProvider(widget.caseId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('病例详情'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => context.push('/screening/${widget.caseId}'),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('筛查快照'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.primary,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: AppEmptyState(
                icon: Icons.folder_off_outlined,
                title: '病例不存在',
                description: '当前 mock 数据中没有找到对应病例',
              ),
            );
          }
          selectedEventId ??= detail.timeline.isNotEmpty ? detail.timeline.first.id : null;
          final isDark = theme.brightness == Brightness.dark;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxxxl,
            ),
            children: <Widget>[
              PatientSummaryCard(summary: detail.summary),

              const SizedBox(height: AppSpacing.xl),

              // ===== Section 1: Overview =====
              _OverviewCard(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 2: Diagnosis & Staging =====
              _DiagnosisStagingSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 3: Molecular & Biomarkers =====
              _MolecularBiomarkerSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 4: Treatment Lines =====
              _TreatmentSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 5: Lab Results =====
              _LabResultsSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 6: Imaging & Response =====
              _ImagingSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 7: Adverse Events =====
              _AdverseEventsSection(detail: detail),

              const SizedBox(height: AppSpacing.sm),

              // ===== Section 8: Vitals & Infection =====
              _VitalsInfectionSection(detail: detail),

              // ===== Divider =====
              const SizedBox(height: AppSpacing.sectionGap),
              const Divider(),
              const SizedBox(height: AppSpacing.sectionGap),

              // ===== Timeline (compact + inline expand) =====
              Text('纵向时间线', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (detail.timeline.isEmpty)
                const AppEmptyState(
                  title: '暂无时间线',
                  description: '上传资料后自动生成',
                )
              else
                ...detail.timeline.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final event = entry.value;
                    final isSelected = selectedEventId == event.id;

                    return TimelineEventTile(
                      event: event,
                      selected: isSelected,
                      isFirst: index == 0,
                      isLast: index == detail.timeline.length - 1,
                      onTap: () {
                        setState(() {
                          selectedEventId = event.id;
                          selectedFieldId = null;
                          selectedEvidenceId = null;
                        });
                      },
                      expandedContent: isSelected
                          ? _buildInlineContent(
                              detail: detail,
                              eventId: event.id,
                              theme: theme,
                              isDark: isDark,
                            )
                          : null,
                    );
                  },
                ),
            ],
          );
        },
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: AppErrorState(message: '$error'),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.page),
          child: SkeletonBlock(height: 180),
        ),
      ),
    );
  }

  Widget? _buildInlineContent({
    required CaseDetail detail,
    required String eventId,
    required ThemeData theme,
    required bool isDark,
  }) {
    final fields = detail.structuredFields
        .where((f) => f.eventId == eventId)
        .toList(growable: false);
    final evidence = detail.evidenceDocuments
        .where((d) => d.eventId == eventId)
        .toList(growable: false);

    if (fields.isEmpty && evidence.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(120)
            : AppPalette.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (fields.isNotEmpty) ...<Widget>[
            Text('结构化字段', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < fields.length; i++) ...<Widget>[
              _CompactFieldRow(
                field: fields[i],
                highlighted: selectedFieldId == fields[i].id,
                onTap: () {
                  setState(() {
                    selectedFieldId = fields[i].id;
                    selectedEvidenceId = fields[i].evidenceId;
                  });
                },
              ),
              if (i < fields.length - 1)
                const Divider(height: AppSpacing.md, thickness: 0.5),
            ],
          ],
          if (fields.isNotEmpty && evidence.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const Divider(thickness: 0.5),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (evidence.isNotEmpty) ...<Widget>[
            Text('相关证据', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < evidence.length; i++) ...<Widget>[
              _CompactEvidenceRow(
                document: evidence[i],
                highlighted: selectedEvidenceId == evidence[i].id,
                onTap: () {
                  setState(() {
                    selectedEvidenceId = evidence[i].id;
                    selectedFieldId = evidence[i].linkedFieldIds.firstOrNull;
                  });
                },
              ),
              if (i < evidence.length - 1)
                const Divider(height: AppSpacing.md, thickness: 0.5),
            ],
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// Section 1: Overview (enhanced)
// ==========================================================================

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CollapsibleSection(
      title: '病例概览',
      icon: Icons.article_outlined,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _FactTile(label: '性别/出生年', value: '${detail.sex} / ${detail.birthYear}', width: tileWidth, isDark: isDark),
                  _FactTile(label: '确诊日期', value: detail.diagnosisDate, width: tileWidth, isDark: isDark),
                  _FactTile(label: '疾病状态', value: detail.diseaseStatus, width: tileWidth, isDark: isDark),
                  _FactTile(label: '转移部位', value: detail.metastaticSites, width: tileWidth, isDark: isDark),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '共病：${detail.comorbidities.isEmpty ? '无' : detail.comorbidities.join('、')}',
            style: theme.textTheme.bodyMedium,
          ),
          if (detail.alerts.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ...detail.alerts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.warning_amber_rounded, size: 15, color: AppPalette.warning),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// Section 2: Diagnosis & Staging
// ==========================================================================

class _DiagnosisStagingSection extends StatelessWidget {
  const _DiagnosisStagingSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dx = detail.diagnosis;

    return CollapsibleSection(
      title: '诊断与分期',
      icon: Icons.biotech_outlined,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _FactTile(label: '原发部位编码', value: dx.primarySiteCode.isNotEmpty ? dx.primarySiteCode : '-', width: tileWidth, isDark: isDark),
                  _FactTile(label: 'ICD-10', value: dx.icd10Code.isNotEmpty ? dx.icd10Code : '-', width: tileWidth, isDark: isDark),
                  _FactTile(label: '分期体系', value: dx.stageSystem.isNotEmpty ? dx.stageSystem : '-', width: tileWidth, isDark: isDark),
                  _FactTile(label: 'AJCC 分期', value: dx.ajccStage.isNotEmpty ? dx.ajccStage : '-', width: tileWidth, isDark: isDark),
                ],
              );
            },
          ),
          if (dx.tnmT.isNotEmpty || dx.tnmN.isNotEmpty || dx.tnmM.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                _TnmChip(label: 'T', value: dx.tnmT),
                const SizedBox(width: AppSpacing.sm),
                _TnmChip(label: 'N', value: dx.tnmN),
                const SizedBox(width: AppSpacing.sm),
                _TnmChip(label: 'M', value: dx.tnmM),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('病理诊断', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(dx.pathologyDiagnosis, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TnmChip extends StatelessWidget {
  const _TnmChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppPalette.primarySurface.withAlpha(180),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: <TextSpan>[
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value.isNotEmpty ? value : '-'),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// Section 3: Molecular & Biomarkers
// ==========================================================================

class _MolecularBiomarkerSection extends StatelessWidget {
  const _MolecularBiomarkerSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMolecular = detail.molecularResults.isNotEmpty;
    final hasBiomarker = detail.biomarkers.isNotEmpty;

    return CollapsibleSection(
      title: '分子检测与标志物',
      icon: Icons.science_outlined,
      initiallyExpanded: true,
      trailing: hasMolecular
          ? StatusBadge(label: '${detail.molecularResults.length} 项基因', tone: StatusTone.pending)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasMolecular) ...[
            Text('基因检测', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            ...detail.molecularResults.map((m) => _MolecularRow(result: m)),
          ],
          if (hasMolecular && hasBiomarker) const SizedBox(height: AppSpacing.lg),
          if (hasBiomarker) ...[
            Text('生物标志物', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: detail.biomarkers
                  .map((b) => _BiomarkerChip(biomarker: b))
                  .toList(growable: false),
            ),
          ],
          if (!hasMolecular && !hasBiomarker)
            Text('暂无分子检测数据', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MolecularRow extends StatelessWidget {
  const _MolecularRow({required this.result});

  final MolecularResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (result.status) {
      MolecularStatus.positive => StatusTone.error,
      MolecularStatus.negative => StatusTone.success,
      MolecularStatus.notTested => StatusTone.pending,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(result.gene, style: theme.textTheme.titleSmall),
                if (result.variant.isNotEmpty && result.variant != '-')
                  Text(result.variant, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (result.sampleType.isNotEmpty && result.sampleType != '-')
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(result.sampleType, style: theme.textTheme.bodySmall),
            ),
          StatusBadge(label: MolecularStatusX(result.status).label, tone: tone),
        ],
      ),
    );
  }
}

class _BiomarkerChip extends StatelessWidget {
  const _BiomarkerChip({required this.biomarker});

  final BiomarkerResult biomarker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        '${biomarker.name}: ${biomarker.value}',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ==========================================================================
// Section 4: Treatment Lines
// ==========================================================================

class _TreatmentSection extends StatelessWidget {
  const _TreatmentSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (detail.treatmentLines.isEmpty) {
      return CollapsibleSection(
        title: '治疗用药',
        icon: Icons.medication_outlined,
        child: Text('暂无治疗记录', style: theme.textTheme.bodySmall),
      );
    }

    return CollapsibleSection(
      title: '治疗用药',
      icon: Icons.medication_outlined,
      trailing: StatusBadge(
        label: '${detail.treatmentLines.length} 线',
        tone: StatusTone.pending,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detail.treatmentLines.map((line) => _TreatmentLineCard(line: line)).toList(growable: false),
      ),
    );
  }
}

class _TreatmentLineCard extends StatelessWidget {
  const _TreatmentLineCard({required this.line});

  final TreatmentLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.primary.withAlpha(12) : AppPalette.primarySurface.withAlpha(120),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusBadge(label: '${line.lineNo}L', tone: StatusTone.pending),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(line.regimenName, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${line.regimenType} · ${line.startDate}${line.endDate != null ? ' → ${line.endDate}' : ' → 进行中'}',
            style: theme.textTheme.bodySmall,
          ),
          if (line.drugs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: line.drugs
                  .map((d) => Chip(
                        label: Text(d.drugGeneric, style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// Section 5: Lab Results
// ==========================================================================

class _LabResultsSection extends StatelessWidget {
  const _LabResultsSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (detail.labPanels.isEmpty) {
      return CollapsibleSection(
        title: '检验结果',
        icon: Icons.science_outlined,
        child: Text('暂无检验数据', style: theme.textTheme.bodySmall),
      );
    }

    final abnormalCount = detail.labPanels
        .expand((p) => p.results)
        .where((r) => r.isAbnormal)
        .length;

    return CollapsibleSection(
      title: '检验结果',
      icon: Icons.analytics_outlined,
      trailing: abnormalCount > 0
          ? StatusBadge(label: '$abnormalCount 项异常', tone: StatusTone.warning)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detail.labPanels.map((panel) => _LabPanelCard(panel: panel)).toList(growable: false),
      ),
    );
  }
}

class _LabPanelCard extends StatelessWidget {
  const _LabPanelCard({required this.panel});

  final LabPanel panel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
          child: Text('采样日期: ${panel.collectionDate}', style: theme.textTheme.labelSmall),
        ),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            TableRow(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
              ),
              children: <Widget>[
                _TableHeader('项目'),
                _TableHeader('结果'),
                _TableHeader('单位'),
                _TableHeader('参考范围'),
              ],
            ),
            ...panel.results.map((r) => _labRow(r, theme)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  TableRow _labRow(LabResult r, ThemeData theme) {
    final isAbn = r.isAbnormal;
    final valueColor = isAbn ? AppPalette.error : null;
    final refRange = (r.refLow != null && r.refHigh != null)
        ? '${_num(r.refLow!)} - ${_num(r.refHigh!)}'
        : '-';
    final gradeText = r.ctcaeGrade != null ? '  G${r.ctcaeGrade}' : '';

    return TableRow(
      children: <Widget>[
        _TableCell(
          Text(r.testName, style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isAbn ? FontWeight.w600 : null,
          )),
        ),
        _TableCell(
          Text(
            '${_num(r.value)}$gradeText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueColor,
              fontWeight: isAbn ? FontWeight.w600 : null,
            ),
          ),
        ),
        _TableCell(Text(r.unit, style: theme.textTheme.bodySmall)),
        _TableCell(Text(refRange, style: theme.textTheme.bodySmall)),
      ],
    );
  }

  String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
      child: child,
    );
  }
}

// ==========================================================================
// Section 6: Imaging & Response
// ==========================================================================

class _ImagingSection extends StatelessWidget {
  const _ImagingSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (detail.imagingRecords.isEmpty) {
      return CollapsibleSection(
        title: '影像与疗效',
        icon: Icons.image_search_outlined,
        child: Text('暂无影像数据', style: theme.textTheme.bodySmall),
      );
    }

    return CollapsibleSection(
      title: '影像与疗效',
      icon: Icons.image_search_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detail.imagingRecords.map((rec) {
          final isDark = theme.brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppPalette.primary.withAlpha(12) : AppPalette.primarySurface.withAlpha(120),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StatusBadge(label: rec.studyType),
                    const SizedBox(width: AppSpacing.sm),
                    Text(rec.date, style: theme.textTheme.bodySmall),
                    const Spacer(),
                    if (rec.response != null)
                      StatusBadge(
                        label: 'RECIST: ${rec.response}',
                        tone: _responseTone(rec.response!),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(rec.impression, style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  StatusTone _responseTone(String r) => switch (r) {
    'CR' => StatusTone.success,
    'PR' => StatusTone.success,
    'SD' => StatusTone.warning,
    'PD' => StatusTone.error,
    _ => StatusTone.pending,
  };
}

// ==========================================================================
// Section 7: Adverse Events
// ==========================================================================

class _AdverseEventsSection extends StatelessWidget {
  const _AdverseEventsSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (detail.adverseEvents.isEmpty) {
      return CollapsibleSection(
        title: '不良事件',
        icon: Icons.report_problem_outlined,
        child: Text('暂无不良事件记录', style: theme.textTheme.bodySmall),
      );
    }

    return CollapsibleSection(
      title: '不良事件',
      icon: Icons.report_problem_outlined,
      trailing: StatusBadge(label: '${detail.adverseEvents.length} 项', tone: StatusTone.warning),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detail.adverseEvents.map((ae) {
          final gradeColor = ae.grade >= 3 ? AppPalette.error : ae.grade == 2 ? AppPalette.warning : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(ae.aeTerm, style: theme.textTheme.titleSmall),
                      Text('${ae.startDate} · ${ae.attribution}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(
                  label: 'Grade ${ae.grade}',
                  tone: gradeColor == AppPalette.error
                      ? StatusTone.error
                      : gradeColor == AppPalette.warning
                          ? StatusTone.warning
                          : StatusTone.success,
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

// ==========================================================================
// Section 8: Vitals & Infection
// ==========================================================================

class _VitalsInfectionSection extends StatelessWidget {
  const _VitalsInfectionSection({required this.detail});

  final CaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vs = detail.vitalSigns;

    return CollapsibleSection(
      title: '体征与感染',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _FactTile(label: 'ECOG 评分', value: '${vs.ecog}', width: tileWidth, isDark: isDark),
                  _FactTile(label: '体重', value: vs.weight != null ? '${vs.weight} kg' : '-', width: tileWidth, isDark: isDark),
                ],
              );
            },
          ),
          if (detail.infectionStatus != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 16, color: AppPalette.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '乙肝状态: ${detail.infectionStatus!.hbvStatus}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================================================
// Shared: FactTile & StructuredFieldTile (unchanged)
// ==========================================================================

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.label,
    required this.value,
    required this.width,
    required this.isDark,
  });

  final String label;
  final String value;
  final double width;
  final bool isDark;

  static const _pendingValue = '待补录';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = value == _pendingValue;

    final bgColor = isPending
        ? AppPalette.error.withAlpha(isDark ? 25 : 18)
        : isDark
            ? AppPalette.primary.withAlpha(12)
            : AppPalette.primarySurface.withAlpha(150);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isPending ? Border.all(color: AppPalette.error.withAlpha(60)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: isPending
                  ? theme.textTheme.titleSmall?.copyWith(
                      color: AppPalette.error,
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactFieldRow extends StatelessWidget {
  const _CompactFieldRow({
    required this.field,
    required this.highlighted,
    required this.onTap,
  });

  final StructuredField field;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = switch (field.confidence) {
      FieldConfidence.verified => StatusTone.success,
      FieldConfidence.aiHigh => StatusTone.pending,
      FieldConfidence.aiMedium => StatusTone.warning,
      FieldConfidence.missing => StatusTone.error,
      FieldConfidence.conflict => StatusTone.conflict,
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: highlighted ? AppPalette.primary.withAlpha(12) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(field.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${field.value}  ·  ${field.group}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                StatusBadge(label: field.confidence.label, tone: tone),
                if (field.isBlocking)
                  const StatusBadge(label: '阻断项', tone: StatusTone.error),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEvidenceRow extends StatelessWidget {
  const _CompactEvidenceRow({
    required this.document,
    required this.highlighted,
    required this.onTap,
  });

  final EvidenceDocument document;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: highlighted ? AppPalette.primary.withAlpha(12) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              _modalityIcon(document.modality),
              size: 16,
              color: AppPalette.muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(document.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${document.dateLabel} · ${document.source}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppPalette.muted),
          ],
        ),
      ),
    );
  }

  static IconData _modalityIcon(DocumentModality modality) => switch (modality) {
    DocumentModality.image => Icons.image_outlined,
    DocumentModality.pdf => Icons.description_outlined,
    DocumentModality.audio => Icons.mic_outlined,
    DocumentModality.text => Icons.article_outlined,
  };
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
