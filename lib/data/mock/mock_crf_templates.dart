import '../../core/constants/app_enums.dart';
import '../../features/crf/domain/crf_models.dart';

const mockDiseaseProfiles = <DiseaseProfile>[
  DiseaseProfile(
    id: 'gu-general',
    groupCode: 'GU',
    groupName: '泌尿生殖系统恶性肿瘤',
    tumorCode: 'general',
    tumorName: '泌尿生殖通用',
    defaultTemplateId: 'gu-crf-v2026-03',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'gu-bladder',
    groupCode: 'GU',
    groupName: '泌尿生殖系统恶性肿瘤',
    tumorCode: 'bladder',
    tumorName: '膀胱癌',
    defaultTemplateId: 'gu-crf-v2026-03',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'gu-prostate',
    groupCode: 'GU',
    groupName: '泌尿生殖系统恶性肿瘤',
    tumorCode: 'prostate',
    tumorName: '前列腺癌',
    defaultTemplateId: 'gu-crf-v2026-03',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'lung-nsclc',
    groupCode: 'LUNG',
    groupName: '肺癌',
    tumorCode: 'nsclc',
    tumorName: '非小细胞肺癌',
    defaultTemplateId: 'lung-crf-v2026-01',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'breast-general',
    groupCode: 'BREAST',
    groupName: '乳腺癌',
    tumorCode: 'general',
    tumorName: '乳腺癌',
    defaultTemplateId: 'breast-crf-v2026-01',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'gi-general',
    groupCode: 'GI',
    groupName: '消化道肿瘤',
    tumorCode: 'general',
    tumorName: '消化道通用',
    defaultTemplateId: 'gi-crf-v2026-01',
    enabled: true,
  ),
  DiseaseProfile(
    id: 'gyn-general',
    groupCode: 'GYN',
    groupName: '妇科肿瘤',
    tumorCode: 'general',
    tumorName: '妇科通用',
    defaultTemplateId: 'gyn-crf-v2026-01',
    enabled: true,
  ),
];

final mockCrfTemplates = <CRFTemplate>[
  _guTemplate,
  _lungTemplate,
  _breastTemplate,
  _giTemplate,
  _gynTemplate,
];

List<DiseaseProfile> get enabledMockDiseaseProfiles => mockDiseaseProfiles
    .where((profile) => profile.enabled)
    .toList(growable: false);

DiseaseProfile mockDiseaseProfileById(String profileId) =>
    mockDiseaseProfiles.firstWhere(
      (profile) => profile.id == profileId,
      orElse: () => mockDiseaseProfiles.first,
    );

CRFTemplate mockCrfTemplateById(String templateId) =>
    mockCrfTemplates.firstWhere(
      (template) => template.id == templateId,
      orElse: () => _guTemplate,
    );

CRFTemplate mockTemplateForProfile(String profileId) {
  final profile = mockDiseaseProfileById(profileId);
  return mockCrfTemplateById(profile.defaultTemplateId);
}

DiseaseProfile inferDiseaseProfile({
  required String primarySite,
  required String tumorType,
}) {
  if (primarySite.contains('膀胱') || tumorType.contains('膀胱')) {
    return mockDiseaseProfileById('gu-bladder');
  }
  if (primarySite.contains('前列腺') || tumorType.contains('前列腺')) {
    return mockDiseaseProfileById('gu-prostate');
  }
  if (primarySite.contains('肾') || tumorType.contains('肾')) {
    return mockDiseaseProfileById('gu-general');
  }
  if (primarySite.contains('肺') || tumorType.contains('肺')) {
    return mockDiseaseProfileById('lung-nsclc');
  }
  if (primarySite.contains('乳腺') || tumorType.contains('乳腺')) {
    return mockDiseaseProfileById('breast-general');
  }
  if (primarySite.contains('卵巢') ||
      primarySite.contains('宫颈') ||
      primarySite.contains('子宫')) {
    return mockDiseaseProfileById('gyn-general');
  }
  if (primarySite.contains('胃') ||
      primarySite.contains('食管') ||
      primarySite.contains('结直肠') ||
      primarySite.contains('肝') ||
      primarySite.contains('胰腺')) {
    return mockDiseaseProfileById('gi-general');
  }
  return mockDiseaseProfileById('gu-general');
}

CRFField? findCrfField(CRFTemplate template, String fieldCode) =>
    template.fieldByCode(fieldCode);

FieldMapping? findFieldMapping(CRFTemplate template, String fieldCode) {
  for (final mapping in template.fieldMappings) {
    if (mapping.crfFieldCode == fieldCode) return mapping;
  }
  return null;
}

String? fieldCodeForExtraction(CRFTemplate template, String fieldName) {
  final normalized = fieldName.trim();
  for (final field in template.fields) {
    if (field.label == normalized) return field.fieldCode;
  }
  const aliases = <String, String>{
    'ECOG评分': 'gu.admission.ecog',
    '肉眼血尿': 'gu.admission.gross_hematuria',
    '尿路梗阻程度': 'gu.admission.urinary_obstruction',
    '病理类型': 'gu.pathology.histology_type',
    '病理组织学分类': 'gu.pathology.histology_type',
    'cT': 'gu.pathology.ct',
    'cN': 'gu.pathology.cn',
    'cM': 'gu.pathology.cm',
    'pT': 'gu.pathology.pt',
    'pN': 'gu.pathology.pn',
    'pM': 'gu.pathology.pm',
    'PD-L1 TPS': 'gu.pathology.pd_l1',
    'PD-L1': 'gu.pathology.pd_l1',
    'MSI': 'gu.pathology.msi',
    'HER2': 'gu.pathology.her2',
    'Ki-67': 'gu.pathology.ki67',
    'CPS得分': 'gu.pathology.cps_score',
    'PSA': 'gu.lab.psa',
    'eGFR': 'gu.lab.egfr',
    '当前方案': 'gu.treatment.current_systemic_regimen',
    '疗效评估': 'gu.response.best_response',
    '最佳疗效': 'gu.response.best_response',
  };
  final candidate = aliases[normalized];
  if (candidate == null || template.fieldByCode(candidate) == null) {
    return null;
  }
  return candidate;
}

CRFCompleteness calculateCrfCompleteness(
  CRFTemplate template,
  List<CaseCRFValue> values,
) {
  final byCode = <String, CaseCRFValue>{
    for (final value in values) value.fieldCode: value,
  };
  var completed = 0;
  var blockingMissing = 0;
  var recommendedMissing = 0;
  var conflict = 0;

  for (final field in template.fields) {
    if (field.needsGovernance) continue;
    final value = byCode[field.fieldCode];
    if (value?.status == CRFValueStatus.conflict) {
      conflict += 1;
    }
    if (value?.isComplete == true) {
      completed += 1;
      continue;
    }
    if (field.requiredLevel == RequiredLevel.blocking) {
      blockingMissing += 1;
    } else if (field.requiredLevel == RequiredLevel.recommended) {
      recommendedMissing += 1;
    }
  }

  final activeTotal = template.fields
      .where((field) => !field.needsGovernance)
      .length;
  return CRFCompleteness(
    totalCount: activeTotal,
    completedCount: completed,
    blockingMissingCount: blockingMissing,
    recommendedMissingCount: recommendedMissing,
    conflictCount: conflict,
    governanceCount: template.governanceFieldCount,
  );
}

List<CaseCRFValue> buildMockCrfValues({
  required String caseId,
  required CRFTemplate template,
  required DiseaseProfile profile,
  required String patientCode,
  required String histology,
  required String stage,
  required String regimen,
  required int ecog,
  required bool incompleteCanonical,
  required bool partialCanonical,
}) {
  final values = <String, String>{
    'gu.basic.patient_code': patientCode,
    'gu.admission.ecog': incompleteCanonical ? '' : '$ecog',
    'gu.admission.gross_hematuria': '有',
    'gu.admission.urinary_obstruction': profile.groupCode == 'GU' ? '中度' : '',
    'gu.pathology.histology_type': histology,
    'gu.pathology.ct': 'T2',
    'gu.pathology.cn': 'N0',
    'gu.pathology.cm': 'M0',
    'gu.pathology.pt': profile.tumorCode == 'bladder' ? 'pT2' : 'pT1',
    'gu.pathology.pn': 'pN0',
    'gu.pathology.pm': 'pM0',
    'gu.pathology.lymph_nodes_count': '12',
    'gu.pathology.positive_nodes_count': '0',
    'gu.pathology.margin_status': '阴性',
    'gu.pathology.tumor_location': profile.tumorCode == 'bladder'
        ? '膀胱侧壁'
        : '原发灶',
    'gu.pathology.pd_l1': partialCanonical ? '' : '高表达',
    'gu.pathology.msi': 'MSS',
    'gu.pathology.her2': '阴性',
    'gu.pathology.ki67': '35%',
    'gu.pathology.cps_score': partialCanonical ? '' : '18',
    'gu.lab.psa': profile.tumorCode == 'prostate' ? '14.2' : '不适用',
    'gu.lab.egfr': '92',
    'gu.treatment.current_systemic_regimen': incompleteCanonical ? '' : regimen,
    'gu.response.best_response': 'PR',
    'lung.pathology.egfr': 'L858R',
    'lung.pathology.alk': '阴性',
    'lung.pathology.pd_l1_tps': partialCanonical ? '' : '70%',
    'lung.stage.tnm': stage,
    'lung.treatment.current_regimen': incompleteCanonical ? '' : regimen,
    'breast.pathology.er': '40%',
    'breast.pathology.pr': '10%',
    'breast.pathology.her2': 'IHC 1+',
    'breast.pathology.ki67': '35%',
    'breast.treatment.current_regimen': incompleteCanonical ? '' : regimen,
    'gi.pathology.msi': 'MSS',
    'gi.pathology.her2': 'IHC 2+/FISH-',
    'gi.pathology.ras': 'KRAS G12D',
    'gi.treatment.current_regimen': incompleteCanonical ? '' : regimen,
    'gyn.pathology.brca': '未检',
    'gyn.pathology.hrd': 'Score 56',
    'gyn.treatment.current_regimen': incompleteCanonical ? '' : regimen,
  };

  return template.fields
      .map((field) {
        final raw = values[field.fieldCode] ?? '';
        final status = field.fieldCode == 'gu.lab.psa' && raw == '不适用'
            ? CRFValueStatus.notApplicable
            : raw.isEmpty
            ? CRFValueStatus.missing
            : CRFValueStatus.filled;
        return CaseCRFValue(
          caseId: caseId,
          templateId: template.id,
          fieldCode: field.fieldCode,
          value: raw.isEmpty ? '待补录' : raw,
          status: status,
          confidence: status == CRFValueStatus.missing
              ? FieldConfidence.missing
              : FieldConfidence.aiHigh,
          updatedAtLabel: '2026-04-14',
        );
      })
      .toList(growable: false);
}

List<CaseCRFValue> buildEmptyCrfValues({
  required String caseId,
  required CRFTemplate template,
  required String patientCode,
}) {
  return template.fields
      .map((field) {
        final isPatientCode = field.fieldCode.endsWith('.patient_code');
        return CaseCRFValue(
          caseId: caseId,
          templateId: template.id,
          fieldCode: field.fieldCode,
          value: isPatientCode ? patientCode : '待补录',
          status: isPatientCode
              ? CRFValueStatus.filled
              : CRFValueStatus.missing,
          confidence: isPatientCode
              ? FieldConfidence.verified
              : FieldConfidence.missing,
        );
      })
      .toList(growable: false);
}

CRFField _field(
  String code,
  List<String> path,
  String label,
  CRFFieldType type,
  RequiredLevel required, {
  List<String> options = const <String>[],
  String? unit,
  String? format,
  String? source,
  String? description,
  bool searchable = false,
  String? governanceStatus,
}) {
  return CRFField(
    fieldCode: code,
    path: path,
    label: label,
    dataType: type,
    requiredLevel: required,
    options: options,
    unit: unit,
    format: format,
    source: source,
    description: description,
    searchable: searchable,
    governanceStatus: governanceStatus,
  );
}

const _guMappings = <FieldMapping>[
  FieldMapping(
    crfFieldCode: 'gu.admission.ecog',
    canonicalEntity: 'VitalSigns',
    canonicalField: 'ecog',
    mappingType: FieldMappingType.direct,
  ),
  FieldMapping(
    crfFieldCode: 'gu.pathology.pt',
    canonicalEntity: 'Stage',
    canonicalField: 'pathologic_t',
    mappingType: FieldMappingType.normalize,
  ),
  FieldMapping(
    crfFieldCode: 'gu.pathology.pd_l1',
    canonicalEntity: 'Biomarker',
    canonicalField: 'PD-L1',
    mappingType: FieldMappingType.normalize,
  ),
  FieldMapping(
    crfFieldCode: 'gu.pathology.cps_score',
    canonicalEntity: 'Biomarker',
    canonicalField: 'PD-L1_CPS',
    mappingType: FieldMappingType.normalize,
  ),
  FieldMapping(
    crfFieldCode: 'gu.lab.egfr',
    canonicalEntity: 'LabResult',
    canonicalField: 'test_name_std=eGFR',
    mappingType: FieldMappingType.direct,
  ),
  FieldMapping(
    crfFieldCode: 'gu.treatment.current_systemic_regimen',
    canonicalEntity: 'Regimen',
    canonicalField: 'regimen_name_std',
    mappingType: FieldMappingType.normalize,
  ),
  FieldMapping(
    crfFieldCode: 'gu.response.best_response',
    canonicalEntity: 'ResponseAssessment',
    canonicalField: 'response',
    mappingType: FieldMappingType.normalize,
  ),
];

final _guTemplate = CRFTemplate(
  id: 'gu-crf-v2026-03',
  diseaseProfileId: 'gu-general',
  version: 'V2026-03',
  title: '泌尿生殖系统恶性肿瘤专病CRF',
  status: CRFTemplateStatus.active,
  sections: <CRFSection>[
    CRFSection(
      code: 'gu.basic',
      title: '基本信息',
      level: 1,
      fields: <CRFField>[
        _field(
          'gu.basic.patient_code',
          const ['基本信息'],
          '患者编码',
          CRFFieldType.text,
          RequiredLevel.optional,
        ),
      ],
    ),
    CRFSection(
      code: 'gu.admission',
      title: '入院记录',
      level: 1,
      fields: <CRFField>[
        _field(
          'gu.admission.ecog',
          const ['入院记录', '体力状态'],
          'ECOG评分',
          CRFFieldType.number,
          RequiredLevel.blocking,
          format: '0-4',
          source: '病程/随访',
          searchable: true,
        ),
        _field(
          'gu.admission.gross_hematuria',
          const ['入院记录', '症状'],
          '肉眼血尿',
          CRFFieldType.boolean,
          RequiredLevel.recommended,
          options: const ['有', '无', '不详'],
          source: '入院记录',
          searchable: true,
        ),
        _field(
          'gu.admission.urinary_obstruction',
          const ['入院记录', '症状'],
          '尿路梗阻程度',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['无', '轻度', '中度', '重度', '不详'],
          source: '入院记录',
          searchable: true,
        ),
      ],
    ),
    CRFSection(
      code: 'gu.pathology',
      title: '辅助检查 / 病理检查',
      level: 1,
      fields: <CRFField>[
        _field(
          'gu.pathology.histology_type',
          const ['辅助检查', '病理检查'],
          '病理组织学分类',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['尿路上皮癌', '腺癌', '鳞癌', '小细胞癌', '其他'],
          searchable: true,
        ),
        _field(
          'gu.pathology.ct',
          const ['辅助检查', '病理检查', '临床TNM'],
          'cT',
          CRFFieldType.category,
          RequiredLevel.optional,
          options: const ['T0', 'Tis', 'T1', 'T2', 'T3', 'T4'],
          searchable: true,
        ),
        _field(
          'gu.pathology.cn',
          const ['辅助检查', '病理检查', '临床TNM'],
          'cN',
          CRFFieldType.category,
          RequiredLevel.optional,
          options: const ['N0', 'N1', 'N2', 'N3'],
          searchable: true,
        ),
        _field(
          'gu.pathology.cm',
          const ['辅助检查', '病理检查', '临床TNM'],
          'cM',
          CRFFieldType.category,
          RequiredLevel.optional,
          options: const ['M0', 'M1'],
          searchable: true,
        ),
        _field(
          'gu.pathology.pt',
          const ['辅助检查', '病理检查', '术后TNM'],
          'pT',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['pT0', 'pTa', 'pTis', 'pT1', 'pT2', 'pT3', 'pT4'],
          searchable: true,
        ),
        _field(
          'gu.pathology.pn',
          const ['辅助检查', '病理检查', '术后TNM'],
          'pN',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['pN0', 'pN1', 'pN2', 'pN3'],
          searchable: true,
        ),
        _field(
          'gu.pathology.pm',
          const ['辅助检查', '病理检查', '术后TNM'],
          'pM',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['pM0', 'pM1'],
          searchable: true,
        ),
        _field(
          'gu.pathology.lymph_nodes_count',
          const ['辅助检查', '病理检查'],
          '淋巴结数',
          CRFFieldType.number,
          RequiredLevel.optional,
        ),
        _field(
          'gu.pathology.positive_nodes_count',
          const ['辅助检查', '病理检查'],
          '淋巴结转移数',
          CRFFieldType.number,
          RequiredLevel.optional,
          searchable: true,
        ),
        _field(
          'gu.pathology.margin_status',
          const ['辅助检查', '病理检查'],
          '切缘情况',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['阴性', '阳性', '不详'],
          searchable: true,
        ),
        _field(
          'gu.pathology.tumor_location',
          const ['辅助检查', '病理检查'],
          '肿瘤位置',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'gu.pathology.pd_l1',
          const ['辅助检查', '免疫组化'],
          'PD-L1',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['高表达', '低表达', '阴性', '未检'],
          searchable: true,
        ),
        _field(
          'gu.pathology.msi',
          const ['辅助检查', '分子标志物'],
          'MSI',
          CRFFieldType.category,
          RequiredLevel.optional,
          options: const ['MSI-H', 'MSS', '未检'],
          searchable: true,
        ),
        _field(
          'gu.pathology.her2',
          const ['辅助检查', '免疫组化'],
          'HER2',
          CRFFieldType.category,
          RequiredLevel.optional,
          options: const ['0', '1+', '2+', '3+', '阴性', '未检'],
          searchable: true,
        ),
        _field(
          'gu.pathology.ki67',
          const ['辅助检查', '免疫组化'],
          'Ki-67',
          CRFFieldType.text,
          RequiredLevel.optional,
        ),
        _field(
          'gu.pathology.cps_score',
          const ['辅助检查', '免疫组化'],
          'CPS得分',
          CRFFieldType.number,
          RequiredLevel.recommended,
          searchable: true,
        ),
      ],
    ),
    CRFSection(
      code: 'gu.lab',
      title: '实验室检查',
      level: 1,
      fields: <CRFField>[
        _field(
          'gu.lab.psa',
          const ['实验室检查', '肿瘤标志物'],
          'PSA',
          CRFFieldType.number,
          RequiredLevel.optional,
          unit: 'ng/mL',
          searchable: true,
        ),
        _field(
          'gu.lab.egfr',
          const ['实验室检查', '肾功能'],
          'eGFR',
          CRFFieldType.number,
          RequiredLevel.recommended,
          unit: 'mL/min/1.73m²',
          searchable: true,
        ),
        _field(
          'gu.lab.reference_range_note',
          const ['实验室检查', '治理'],
          '参考范围说明',
          CRFFieldType.unknown,
          RequiredLevel.optional,
          governanceStatus: 'need_governance',
        ),
      ],
    ),
    CRFSection(
      code: 'gu.treatment_response',
      title: '诊断和治疗 / 疗效评价',
      level: 1,
      fields: <CRFField>[
        _field(
          'gu.treatment.current_systemic_regimen',
          const ['诊断和治疗', '全身治疗'],
          '当次全身治疗方案',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
        _field(
          'gu.response.best_response',
          const ['疗效评价'],
          '最佳疗效',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['CR', 'PR', 'SD', 'PD', 'NE'],
          searchable: true,
        ),
      ],
    ),
  ],
  fieldMappings: _guMappings,
);

final _lungTemplate = CRFTemplate(
  id: 'lung-crf-v2026-01',
  diseaseProfileId: 'lung-nsclc',
  version: 'V2026-01',
  title: '肺癌专病CRF',
  status: CRFTemplateStatus.active,
  sections: <CRFSection>[
    CRFSection(
      code: 'lung.pathology',
      title: '病理与分子',
      level: 1,
      fields: <CRFField>[
        _field(
          'lung.pathology.egfr',
          const ['病理与分子'],
          'EGFR',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['阳性', '阴性', '未检', 'L858R', '19del'],
          searchable: true,
        ),
        _field(
          'lung.pathology.alk',
          const ['病理与分子'],
          'ALK',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['阳性', '阴性', '未检'],
          searchable: true,
        ),
        _field(
          'lung.pathology.pd_l1_tps',
          const ['病理与分子'],
          'PD-L1 TPS',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
      ],
    ),
    CRFSection(
      code: 'lung.stage_treatment',
      title: '分期与治疗',
      level: 1,
      fields: <CRFField>[
        _field(
          'lung.stage.tnm',
          const ['分期'],
          'TNM分期',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
        _field(
          'lung.treatment.current_regimen',
          const ['治疗'],
          '当前方案',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
      ],
    ),
  ],
  fieldMappings: const <FieldMapping>[
    FieldMapping(
      crfFieldCode: 'lung.pathology.pd_l1_tps',
      canonicalEntity: 'Biomarker',
      canonicalField: 'PD-L1_TPS',
      mappingType: FieldMappingType.normalize,
    ),
  ],
);

final _breastTemplate = CRFTemplate(
  id: 'breast-crf-v2026-01',
  diseaseProfileId: 'breast-general',
  version: 'V2026-01',
  title: '乳腺癌专病CRF',
  status: CRFTemplateStatus.active,
  sections: <CRFSection>[
    CRFSection(
      code: 'breast.pathology',
      title: '病理与受体',
      level: 1,
      fields: <CRFField>[
        _field(
          'breast.pathology.er',
          const ['病理与受体'],
          'ER',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'breast.pathology.pr',
          const ['病理与受体'],
          'PR',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'breast.pathology.her2',
          const ['病理与受体'],
          'HER2',
          CRFFieldType.category,
          RequiredLevel.blocking,
          options: const ['0', '1+', '2+', '3+', 'FISH+', 'FISH-'],
          searchable: true,
        ),
        _field(
          'breast.pathology.ki67',
          const ['病理与受体'],
          'Ki-67',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'breast.treatment.current_regimen',
          const ['治疗'],
          '当前方案',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
      ],
    ),
  ],
  fieldMappings: const <FieldMapping>[],
);

final _giTemplate = CRFTemplate(
  id: 'gi-crf-v2026-01',
  diseaseProfileId: 'gi-general',
  version: 'V2026-01',
  title: '消化道肿瘤专病CRF',
  status: CRFTemplateStatus.active,
  sections: <CRFSection>[
    CRFSection(
      code: 'gi.pathology',
      title: '病理与分子',
      level: 1,
      fields: <CRFField>[
        _field(
          'gi.pathology.msi',
          const ['病理与分子'],
          'MSI/MMR',
          CRFFieldType.category,
          RequiredLevel.recommended,
          options: const ['MSI-H', 'MSS', 'dMMR', 'pMMR', '未检'],
          searchable: true,
        ),
        _field(
          'gi.pathology.her2',
          const ['病理与分子'],
          'HER2',
          CRFFieldType.text,
          RequiredLevel.optional,
          searchable: true,
        ),
        _field(
          'gi.pathology.ras',
          const ['病理与分子'],
          'RAS/BRAF',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'gi.treatment.current_regimen',
          const ['治疗'],
          '当前方案',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
      ],
    ),
  ],
  fieldMappings: const <FieldMapping>[],
);

final _gynTemplate = CRFTemplate(
  id: 'gyn-crf-v2026-01',
  diseaseProfileId: 'gyn-general',
  version: 'V2026-01',
  title: '妇科肿瘤专病CRF',
  status: CRFTemplateStatus.active,
  sections: <CRFSection>[
    CRFSection(
      code: 'gyn.pathology',
      title: '病理与分子',
      level: 1,
      fields: <CRFField>[
        _field(
          'gyn.pathology.brca',
          const ['病理与分子'],
          'BRCA',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'gyn.pathology.hrd',
          const ['病理与分子'],
          'HRD',
          CRFFieldType.text,
          RequiredLevel.recommended,
          searchable: true,
        ),
        _field(
          'gyn.treatment.current_regimen',
          const ['治疗'],
          '当前方案',
          CRFFieldType.text,
          RequiredLevel.blocking,
          searchable: true,
        ),
      ],
    ),
  ],
  fieldMappings: const <FieldMapping>[],
);
