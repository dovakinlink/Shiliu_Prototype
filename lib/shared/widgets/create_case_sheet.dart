import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock/mock_crf_templates.dart';
import '../../data/mock/mock_repositories.dart';
import '../../features/case_detail/domain/case_models.dart';

class CreateCaseSheet extends ConsumerStatefulWidget {
  const CreateCaseSheet({this.onCreated, super.key});

  final ValueChanged<CaseSummary>? onCreated;

  @override
  ConsumerState<CreateCaseSheet> createState() => _CreateCaseSheetState();
}

class _CreateCaseSheetState extends ConsumerState<CreateCaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthYearController = TextEditingController();

  String _sex = '男';
  String? _primarySite;
  String? _tumorType;
  String? _diseaseProfileId;
  String? _histology;
  String? _stage;
  bool _submitting = false;

  static const _primarySites = <String>[
    '肺',
    '胃',
    '食管',
    '乳腺',
    '卵巢',
    '结直肠',
    '肝',
    '纵隔',
    '肾',
    '膀胱',
    '前列腺',
    '头颈',
    '甲状腺',
    '子宫',
    '宫颈',
    '皮肤',
    '胰腺',
    '淋巴',
  ];

  static const _tumorTypesBySite = <String, List<String>>{
    '肺': ['非小细胞肺癌', '小细胞肺癌', '肺腺癌', '肺鳞癌'],
    '胃': ['胃癌', '胃腺癌', '胃淋巴瘤'],
    '食管': ['食管鳞癌', '食管腺癌'],
    '乳腺': ['三阴性乳腺癌', 'HER2 低表达乳腺癌', 'HER2 阳性乳腺癌', 'HR 阳性乳腺癌'],
    '卵巢': ['高级别浆液性卵巢癌', '透明细胞癌', '子宫内膜样癌'],
    '结直肠': ['结直肠腺癌', '直肠鳞癌'],
    '肝': ['肝细胞癌', '胆管细胞癌'],
    '纵隔': ['胸腺瘤', '胸腺鳞癌', '胸部罕见肿瘤'],
    '肾': ['肾透明细胞癌', '肾乳头状癌'],
    '膀胱': ['膀胱尿路上皮癌'],
    '前列腺': ['前列腺腺癌'],
    '头颈': ['鼻咽癌', '口腔鳞癌', '喉癌'],
    '甲状腺': ['甲状腺乳头状癌', '甲状腺未分化癌'],
    '子宫': ['子宫内膜癌', '子宫肉瘤'],
    '宫颈': ['宫颈鳞癌', '宫颈腺癌'],
    '皮肤': ['黑色素瘤', '基底细胞癌', '鳞状细胞癌'],
    '胰腺': ['胰腺导管腺癌', '胰腺神经内分泌瘤'],
    '淋巴': ['弥漫大B细胞淋巴瘤', '霍奇金淋巴瘤', '滤泡性淋巴瘤'],
  };

  static const _stages = <String>[
    'I期',
    'II期',
    'IIA期',
    'IIB期',
    'III期',
    'IIIA期',
    'IIIB期',
    'IV期',
    'IVA期',
    'IVB期',
  ];

  List<String> get _availableTumorTypes =>
      _tumorTypesBySite[_primarySite] ?? const <String>[];

  @override
  void dispose() {
    _nameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final summary = await ref
          .read(caseRepositoryProvider)
          .createCase(
            patientName: _nameController.text.trim(),
            sex: _sex,
            birthYear: int.parse(_birthYearController.text.trim()),
            primarySite: _primarySite!,
            tumorType: _tumorType!,
            diseaseProfileId: _diseaseProfileId,
            histology: _histology,
            stage: _stage,
          );
      if (!mounted) return;
      widget.onCreated?.call(summary);
      Navigator.of(context).pop(summary);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl + insets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppPalette.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                      color: AppPalette.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('新建病例', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('录入患者基本信息以创建病例档案', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                '患者信息',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppPalette.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '患者姓名',
                  hintText: '例如：张先生',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? '请输入患者姓名' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: const InputDecoration(
                        labelText: '性别',
                        prefixIcon: Icon(Icons.wc_rounded, size: 20),
                      ),
                      items: const <String>['男', '女']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _sex = value ?? _sex),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _birthYearController,
                      decoration: const InputDecoration(
                        labelText: '出生年份',
                        hintText: '例如：1965',
                        prefixIcon: Icon(Icons.cake_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入出生年份';
                        }
                        final year = int.tryParse(value.trim());
                        if (year == null || year < 1900 || year > 2026) {
                          return '请输入有效年份';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),
              Text(
                '疾病信息',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppPalette.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                initialValue: _primarySite,
                decoration: const InputDecoration(
                  labelText: '原发部位',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                items: _primarySites
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(growable: false),
                validator: (value) => value == null ? '请选择原发部位' : null,
                onChanged: (value) {
                  setState(() {
                    _primarySite = value;
                    _tumorType = null;
                    _histology = null;
                    if (value != null) {
                      _diseaseProfileId = inferDiseaseProfile(
                        primarySite: value,
                        tumorType: '',
                      ).id;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<String>(
                initialValue: _tumorType,
                decoration: const InputDecoration(
                  labelText: '瘤种/诊断',
                  prefixIcon: Icon(Icons.biotech_outlined, size: 20),
                ),
                items: _availableTumorTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(growable: false),
                validator: (value) => value == null ? '请选择瘤种' : null,
                onChanged: (value) => setState(() {
                  _tumorType = value;
                  if (_primarySite != null && value != null) {
                    _diseaseProfileId = inferDiseaseProfile(
                      primarySite: _primarySite!,
                      tumorType: value,
                    ).id;
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<String>(
                initialValue: _diseaseProfileId,
                decoration: const InputDecoration(
                  labelText: '瘤种包 / CRF 模板',
                  prefixIcon: Icon(Icons.account_tree_outlined, size: 20),
                ),
                items: enabledMockDiseaseProfiles
                    .map(
                      (profile) => DropdownMenuItem(
                        value: profile.id,
                        child: Text(
                          '${profile.groupCode} · ${profile.tumorName} · ${mockTemplateForProfile(profile.id).version}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) => value == null ? '请选择瘤种包' : null,
                onChanged: (value) => setState(() => _diseaseProfileId = value),
              ),
              const SizedBox(height: AppSpacing.lg),

              DropdownButtonFormField<String>(
                initialValue: _stage,
                decoration: const InputDecoration(
                  labelText: '临床分期（选填）',
                  prefixIcon: Icon(Icons.assessment_outlined, size: 20),
                ),
                items: _stages
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _stage = value),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('创建病例'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
