import '../../core/constants/app_enums.dart';
import '../../core/utils/date_formatters.dart';
import '../../features/case_detail/domain/case_models.dart';
import '../../features/crf/domain/crf_models.dart';
import '../../features/intake/domain/upload_job.dart';
import '../../features/screening/domain/screening_models.dart';
import 'mock_crf_templates.dart';

class MockCaseBundle {
  const MockCaseBundle({required this.detail, required this.screening});

  final CaseDetail detail;
  final ScreeningSnapshot screening;

  MockCaseBundle copyWith({CaseDetail? detail, ScreeningSnapshot? screening}) {
    return MockCaseBundle(
      detail: detail ?? this.detail,
      screening: screening ?? this.screening,
    );
  }
}

// ---------------------------------------------------------------------------
// Per-tumor-type reference data tables
// ---------------------------------------------------------------------------

const _primarySiteCodes = <String>[
  'C34.9', // 肺
  'C16.9', // 胃
  'C15.9', // 食管
  'C50.9', // 乳腺
  'C67.9', // 膀胱
  'C18.9', // 结直肠
  'C22.0', // 肝
  'C37.9', // 纵隔(胸腺)
];

const _icd10Codes = <String>[
  'C34.9',
  'C16.9',
  'C15.5',
  'C50.9',
  'C67.9',
  'C18.9',
  'C22.0',
  'C37',
];

const _pathDiagnoses = <String>[
  '右肺下叶中分化腺癌，浸润性生长',
  '胃体低分化腺癌伴黏液分泌',
  '食管中段鳞状细胞癌，中分化',
  '左乳浸润性导管癌，HER2低表达',
  '膀胱高级别尿路上皮癌，侵及肌层',
  '乙状结肠中分化腺癌，侵及浆膜层',
  '肝右叶肝细胞癌，Edmondson II级',
  '前纵隔胸腺鳞状细胞癌',
];

const _stageSystems = <String>[
  'AJCC 8th',
  'AJCC 8th',
  'AJCC 8th',
  'AJCC 8th',
  'AJCC 8th',
  'AJCC 8th',
  'BCLC+AJCC 8th',
  'Masaoka-Koga',
];

const _tnmTs = <String>['T2b', 'T3', 'T3', 'T2', 'T2', 'T3', 'T2', 'T3'];
const _tnmNs = <String>['N2', 'N2', 'N1', 'N1', 'N0', 'N1', 'N0', 'N1'];
const _tnmMs = <String>['M1a', 'M0', 'M1', 'M0', 'M0', 'M1', 'M0', 'M1'];
const _ajccStages = <String>[
  'IVA',
  'IIIB',
  'IVB',
  'IIIB',
  'II',
  'IVB',
  'IIIB',
  'IVA',
];

// Molecular results vary by tumor type (slot index)
List<List<MolecularResult>> _buildMolecularResultSets() =>
    <List<MolecularResult>>[
      // 0: 肺
      const <MolecularResult>[
        MolecularResult(
          gene: 'EGFR',
          variant: 'L858R',
          status: MolecularStatus.positive,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'ALK',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'KRAS',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'ROS1',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
      ],
      // 1: 胃
      const <MolecularResult>[
        MolecularResult(
          gene: 'HER2',
          variant: 'IHC 2+/FISH-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'KRAS',
          variant: '-',
          status: MolecularStatus.notTested,
          sampleType: '-',
        ),
      ],
      // 2: 食管
      const <MolecularResult>[
        MolecularResult(
          gene: 'EGFR',
          variant: '-',
          status: MolecularStatus.notTested,
          sampleType: '-',
        ),
      ],
      // 3: 乳腺
      const <MolecularResult>[
        MolecularResult(
          gene: 'HER2',
          variant: 'IHC 1+',
          status: MolecularStatus.positive,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'BRCA1/2',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '血液',
        ),
      ],
      // 4: 泌尿生殖
      const <MolecularResult>[
        MolecularResult(
          gene: 'FGFR3',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'ERBB2',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
      ],
      // 5: 结直肠
      const <MolecularResult>[
        MolecularResult(
          gene: 'KRAS',
          variant: 'G12D',
          status: MolecularStatus.positive,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'BRAF',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
        MolecularResult(
          gene: 'NRAS',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
      ],
      // 6: 肝
      const <MolecularResult>[
        MolecularResult(
          gene: 'TERT',
          variant: 'promoter mut',
          status: MolecularStatus.positive,
          sampleType: '组织',
        ),
      ],
      // 7: 纵隔
      const <MolecularResult>[
        MolecularResult(
          gene: 'KIT',
          variant: '-',
          status: MolecularStatus.negative,
          sampleType: '组织',
        ),
      ],
    ];

const _biomarkerSets = <List<BiomarkerResult>>[
  // 0: 肺
  <BiomarkerResult>[
    BiomarkerResult(name: 'PD-L1 (TPS)', value: '70%'),
    BiomarkerResult(name: 'TMB', value: '12.3 mut/Mb'),
  ],
  // 1: 胃
  <BiomarkerResult>[
    BiomarkerResult(name: 'PD-L1 (CPS)', value: '10'),
    BiomarkerResult(name: 'MSI', value: 'MSS'),
    BiomarkerResult(name: 'HER2', value: 'IHC 2+/FISH-'),
  ],
  // 2: 食管
  <BiomarkerResult>[BiomarkerResult(name: 'PD-L1 (CPS)', value: '15')],
  // 3: 乳腺
  <BiomarkerResult>[
    BiomarkerResult(name: 'ER', value: '40%'),
    BiomarkerResult(name: 'PR', value: '10%'),
    BiomarkerResult(name: 'HER2', value: 'IHC 1+'),
    BiomarkerResult(name: 'Ki-67', value: '35%'),
  ],
  // 4: 泌尿生殖
  <BiomarkerResult>[
    BiomarkerResult(name: 'PD-L1 (CPS)', value: '18'),
    BiomarkerResult(name: 'MSI', value: 'MSS'),
    BiomarkerResult(name: 'HER2', value: '阴性'),
  ],
  // 5: 结直肠
  <BiomarkerResult>[
    BiomarkerResult(name: 'MSI', value: 'MSS'),
    BiomarkerResult(name: 'KRAS', value: 'G12D 突变'),
    BiomarkerResult(name: 'CEA', value: '28.5 ng/mL'),
  ],
  // 6: 肝
  <BiomarkerResult>[
    BiomarkerResult(name: 'AFP', value: '580 ng/mL'),
    BiomarkerResult(name: 'HBV DNA', value: '< 20 IU/mL'),
  ],
  // 7: 纵隔
  <BiomarkerResult>[
    BiomarkerResult(name: 'PD-L1 (TPS)', value: '5%'),
    BiomarkerResult(name: 'KIT', value: '阴性'),
  ],
];

// Per-slot treatment lines
List<TreatmentLine> _treatmentLinesForSlot(
  int slot,
  int maxLine,
  DateTime now,
) {
  final lines = <TreatmentLine>[];
  final regimenData = <List<_RegimenSpec>>[
    // 0: 肺
    [
      _RegimenSpec(
        '培美曲塞+顺铂+帕博利珠单抗',
        '化免联合',
        ['培美曲塞', '顺铂', '帕博利珠单抗'],
        ['化疗-叶酸拮抗', '化疗-铂类', 'PD-1'],
      ),
      _RegimenSpec('帕博利珠单抗单药维持', '免疫单药', ['帕博利珠单抗'], ['PD-1']),
    ],
    // 1: 胃
    [
      _RegimenSpec(
        'SOX + 信迪利单抗',
        '化免联合',
        ['奥沙利铂', '替吉奥', '信迪利单抗'],
        ['化疗-铂类', '化疗-氟尿嘧啶', 'PD-1'],
      ),
    ],
    // 2: 食管
    [
      _RegimenSpec('紫杉醇+纳武利尤单抗', '化免联合', ['紫杉醇', '纳武利尤单抗'], ['化疗-紫杉', 'PD-1']),
    ],
    // 3: 乳腺
    [
      _RegimenSpec('T-DXd (ADC)', 'ADC', ['T-DXd'], ['ADC']),
    ],
    // 4: 泌尿生殖
    [
      _RegimenSpec('吉西他滨+顺铂', '含铂化疗', ['吉西他滨', '顺铂'], ['化疗-核苷类似物', '化疗-铂类']),
    ],
    // 5: 结直肠
    [
      _RegimenSpec(
        'FOLFIRI + 贝伐珠单抗',
        '化疗+抗血管',
        ['伊立替康', '氟尿嘧啶', '亚叶酸钙', '贝伐珠单抗'],
        ['化疗-拓扑异构酶', '化疗-氟尿嘧啶', '辅助', '抗VEGF'],
      ),
    ],
    // 6: 肝
    [
      _RegimenSpec(
        '阿替利珠单抗+贝伐珠单抗',
        '免疫+抗血管',
        ['阿替利珠单抗', '贝伐珠单抗'],
        ['PD-L1', '抗VEGF'],
      ),
    ],
    // 7: 纵隔
    [_RegimenSpec('临床试验筛查中', '待定', <String>[], <String>[])],
  ];

  final specs = regimenData[slot];
  for (int l = 1; l <= maxLine && l <= specs.length; l++) {
    final s = specs[l - 1];
    final startDay = now.subtract(Duration(days: 200 - (l - 1) * 90));
    final endDay = l < maxLine
        ? now.subtract(Duration(days: 200 - l * 90))
        : null;
    lines.add(
      TreatmentLine(
        lineNo: l,
        regimenName: s.name,
        regimenType: s.type,
        startDate: conciseDate(startDay),
        endDate: endDay != null ? conciseDate(endDay) : null,
        drugs: List<DrugExposure>.generate(
          s.drugs.length,
          (di) => DrugExposure(
            drugGeneric: s.drugs[di],
            drugClass: s.classes[di],
            startDate: conciseDate(startDay),
            endDate: endDay != null ? conciseDate(endDay) : null,
          ),
        ),
      ),
    );
  }
  if (lines.isEmpty) {
    lines.add(
      TreatmentLine(
        lineNo: 1,
        regimenName: specs.first.name,
        regimenType: specs.first.type,
        startDate: conciseDate(now.subtract(const Duration(days: 120))),
        drugs: const <DrugExposure>[],
      ),
    );
  }
  return lines;
}

class _RegimenSpec {
  const _RegimenSpec(this.name, this.type, this.drugs, this.classes);
  final String name;
  final String type;
  final List<String> drugs;
  final List<String> classes;
}

// Lab panels: normal vs liver-risk
LabPanel _labPanel(DateTime date, bool liverRisk) {
  return LabPanel(
    collectionDate: conciseDate(date),
    results: <LabResult>[
      LabResult(
        testName: 'ALT',
        value: liverRisk ? 128 : 25,
        unit: 'U/L',
        refLow: 7,
        refHigh: 40,
        isAbnormal: liverRisk,
        ctcaeGrade: liverRisk ? 2 : null,
      ),
      LabResult(
        testName: 'AST',
        value: liverRisk ? 96 : 22,
        unit: 'U/L',
        refLow: 13,
        refHigh: 35,
        isAbnormal: liverRisk,
        ctcaeGrade: liverRisk ? 2 : null,
      ),
      LabResult(
        testName: 'TBil',
        value: liverRisk ? 32.1 : 12.4,
        unit: 'µmol/L',
        refLow: 3.4,
        refHigh: 20.5,
        isAbnormal: liverRisk,
        ctcaeGrade: liverRisk ? 1 : null,
      ),
      LabResult(
        testName: 'Alb',
        value: liverRisk ? 31.2 : 42.5,
        unit: 'g/L',
        refLow: 40,
        refHigh: 55,
        isAbnormal: liverRisk,
      ),
      LabResult(
        testName: 'Cr',
        value: 68,
        unit: 'µmol/L',
        refLow: 41,
        refHigh: 81,
        isAbnormal: false,
      ),
      LabResult(
        testName: 'eGFR',
        value: 95,
        unit: 'mL/min/1.73m²',
        refLow: 90,
        refHigh: 120,
        isAbnormal: false,
      ),
      LabResult(
        testName: 'WBC',
        value: 5.8,
        unit: '×10⁹/L',
        refLow: 3.5,
        refHigh: 9.5,
        isAbnormal: false,
      ),
      LabResult(
        testName: 'ANC',
        value: 3.2,
        unit: '×10⁹/L',
        refLow: 1.8,
        refHigh: 6.3,
        isAbnormal: false,
      ),
      LabResult(
        testName: 'HGB',
        value: 118,
        unit: 'g/L',
        refLow: 115,
        refHigh: 150,
        isAbnormal: false,
      ),
      LabResult(
        testName: 'PLT',
        value: 185,
        unit: '×10⁹/L',
        refLow: 125,
        refHigh: 350,
        isAbnormal: false,
      ),
    ],
  );
}

// Imaging records
List<ImagingRecord> _imagingForSlot(int slot, DateTime now) {
  final base = now.subtract(const Duration(days: 30));
  return <ImagingRecord>[
    ImagingRecord(
      studyType: 'CT',
      date: conciseDate(base),
      impression: const <String>[
        '右肺下叶占位较前缩小约15%，纵隔淋巴结稳定',
        '胃壁增厚较前好转，腹膜后淋巴结缩小',
        '食管中段管壁增厚，范围较前缩小',
        '左乳术后改变，腋窝未见明显肿大淋巴结',
        '膀胱左侧壁术后改变，盆腔淋巴结未见明显增大',
        '乙状结肠壁增厚，肝内多发转移灶稳定',
        '肝右叶占位缩小约20%，门脉癌栓未见进展',
        '前纵隔占位较前增大，考虑进展',
      ][slot],
      response: const <String>[
        'PR',
        'PR',
        'SD',
        'CR',
        'PR',
        'SD',
        'PR',
        'PD',
      ][slot],
    ),
    ImagingRecord(
      studyType: slot == 4 ? '超声' : 'MRI',
      date: conciseDate(base.subtract(const Duration(days: 60))),
      impression: const <String>[
        '头颅MRI未见明确转移灶',
        '肝MRI未见明确转移灶',
        '头颅MRI未见异常信号',
        '肝MRI未见异常',
        '盆腔MRI提示膀胱壁局部增厚，未见远处转移',
        '肝MRI转移灶较前稳定',
        '上腹MRI辅助评估，与CT一致',
        '头颅MRI未见转移',
      ][slot],
    ),
  ];
}

// Adverse events
List<AdverseEventRecord> _adverseEventsForCase(
  int index,
  int slot,
  bool liverRisk,
  DateTime now,
) {
  final events = <AdverseEventRecord>[];
  if (liverRisk) {
    events.add(
      AdverseEventRecord(
        aeTerm: '免疫相关性肝损伤',
        grade: 2,
        startDate: conciseDate(now.subtract(Duration(days: 10 + index))),
        attribution: '可能相关',
      ),
    );
  }
  if (index % 3 == 0) {
    events.add(
      AdverseEventRecord(
        aeTerm: '甲状腺功能减退',
        grade: 1,
        startDate: conciseDate(now.subtract(Duration(days: 45 + index))),
        attribution: '很可能相关',
      ),
    );
  }
  if (index % 4 == 1) {
    events.add(
      AdverseEventRecord(
        aeTerm: '骨髓抑制 (中性粒细胞减少)',
        grade: 2,
        startDate: conciseDate(now.subtract(Duration(days: 20 + index * 2))),
        attribution: '肯定相关',
      ),
    );
  }
  if (index % 5 == 2) {
    events.add(
      AdverseEventRecord(
        aeTerm: '皮疹',
        grade: 1,
        startDate: conciseDate(now.subtract(Duration(days: 15 + index))),
        attribution: '可能相关',
      ),
    );
  }
  if (events.isEmpty) {
    events.add(
      AdverseEventRecord(
        aeTerm: '乏力',
        grade: 1,
        startDate: conciseDate(now.subtract(Duration(days: 30 + index))),
        attribution: '可能相关',
      ),
    );
  }
  return events;
}

// ---------------------------------------------------------------------------
// Main builder
// ---------------------------------------------------------------------------

List<MockCaseBundle> buildSeedCaseBundles() {
  const patientNames = <String>[
    '吴女士',
    '赵先生',
    '周女士',
    '钱先生',
    '孙女士',
    '李先生',
    '郑女士',
    '王先生',
    '冯女士',
    '陈先生',
    '褚女士',
    '卫先生',
    '蒋女士',
    '沈先生',
    '韩女士',
    '杨先生',
    '朱女士',
    '秦先生',
    '尤女士',
    '许先生',
    '何女士',
    '吕先生',
    '施女士',
    '张先生',
  ];

  const primarySites = <String>['肺', '胃', '食管', '乳腺', '膀胱', '结直肠', '肝', '纵隔'];
  const tumorTypes = <String>[
    '非小细胞肺癌',
    '胃癌',
    '食管鳞癌',
    'HER2 低表达乳腺癌',
    '膀胱尿路上皮癌',
    '结直肠腺癌',
    '肝细胞癌',
    '胸部罕见肿瘤',
  ];
  const histologies = <String>[
    '肺腺癌',
    '胃腺癌',
    '鳞状细胞癌',
    '浸润性导管癌',
    '尿路上皮癌',
    '中分化腺癌',
    '肝细胞癌',
    '胸腺鳞癌',
  ];
  const diseaseGroups = <String>[
    '胸部肿瘤',
    '消化道肿瘤',
    '消化道肿瘤',
    '乳腺肿瘤',
    '泌尿生殖系统恶性肿瘤',
    '消化道肿瘤',
    '肝胆肿瘤',
    '罕见肿瘤',
  ];
  const stages = <String>[
    'IV期',
    'III期',
    'IV期',
    'IIIB期',
    'II期',
    'IV期',
    'IIIB期',
    'IV期',
  ];
  const regimens = <String>[
    'PD-1 单药维持',
    'SOX + PD-1',
    '紫杉醇 + 纳武利尤单抗',
    'ADC 序贯治疗',
    '吉西他滨 + 顺铂',
    'FOLFIRI + 贝伐珠单抗',
    '阿替利珠单抗 + 抗 VEGF',
    '临床试验筛查中',
  ];
  const diseaseStatuses = <String>[
    '复发转移',
    '治疗中',
    '进展后',
    '维持治疗',
    '术后辅助评估',
    '治疗中',
    '随访中',
    '筛查评估',
  ];
  const comorbiditySets = <List<String>>[
    <String>['2 型糖尿病', '脂肪肝'],
    <String>['高血压'],
    <String>['COPD'],
    <String>['营养不良'],
    <String>['高血压', '慢性肾病'],
    <String>['乙肝携带'],
    <String>['糖尿病'],
    <String>['冠心病'],
  ];
  const biomarkerLabels = <String>[
    'PD-L1 TPS 70%',
    'HER2 低表达',
    'CPS 10',
    'ER 40%',
    'PD-L1 CPS 18',
    'KRAS G12D',
    'HBV DNA 监测中',
    'KIT 未见异常',
  ];

  final now = DateTime(2026, 4, 14);
  final molecularSets = _buildMolecularResultSets();

  return List<MockCaseBundle>.generate(5, (index) {
    final slot = index % primarySites.length;
    final caseId = 'case-${(index + 1).toString().padLeft(3, '0')}';
    final patientCode = 'SHL-${(index + 1).toString().padLeft(3, '0')}';
    final line = (index % 3) + 1;
    final ecog = index % 4 == 0
        ? 2
        : index.isEven
        ? 1
        : 0;
    final liverRisk = index % 5 == 0 || index == 8 || index == 17;
    final hasConflict = index % 6 == 0;
    final baseStatus = switch (index % 3) {
      0 => ScreeningStatus.ready,
      1 => ScreeningStatus.partial,
      _ => ScreeningStatus.notReady,
    };
    final screeningStatus = hasConflict && baseStatus == ScreeningStatus.ready
        ? ScreeningStatus.partial
        : baseStatus;
    final diseaseProfile = inferDiseaseProfile(
      primarySite: primarySites[slot],
      tumorType: tumorTypes[slot],
    );
    final crfTemplate = mockTemplateForProfile(diseaseProfile.id);
    final crfValues = buildMockCrfValues(
      caseId: caseId,
      template: crfTemplate,
      profile: diseaseProfile,
      patientCode: patientCode,
      histology: histologies[slot],
      stage: stages[slot],
      regimen: regimens[slot],
      ecog: ecog,
      incompleteCanonical: baseStatus == ScreeningStatus.notReady,
      partialCanonical: baseStatus == ScreeningStatus.partial,
    );
    final crfCompleteness = calculateCrfCompleteness(crfTemplate, crfValues);
    final tags = <String>[
      diseaseGroups[slot],
      diseaseProfile.groupCode,
      if (baseStatus != ScreeningStatus.notReady &&
          regimens[slot].contains('PD-1') &&
          !regimens[slot].contains('+'))
        'PD-1单药',
      if (liverRisk) '肝功异常',
      if (screeningStatus == ScreeningStatus.ready) '可初筛',
    ];

    final summary = CaseSummary(
      id: caseId,
      patientName: patientNames[index],
      patientCode: patientCode,
      primarySite: primarySites[slot],
      tumorType: tumorTypes[slot],
      histology: histologies[slot],
      stage: stages[slot],
      lineOfTherapy: line,
      currentRegimen: baseStatus == ScreeningStatus.notReady
          ? '待补录'
          : regimens[slot],
      diseaseGroup: diseaseGroups[slot],
      diseaseProfileId: diseaseProfile.id,
      diseaseGroupCode: diseaseProfile.groupCode,
      crfTemplateId: crfTemplate.id,
      crfTemplateVersion: crfTemplate.version,
      crfCompletionRate: crfCompleteness.rate,
      crfBlockingMissingCount: crfCompleteness.blockingMissingCount,
      screeningStatus: screeningStatus,
      ecog: ecog,
      hasLiverRisk: liverRisk,
      tags: tags,
      lastUpdatedLabel: conciseDate(now.subtract(Duration(days: index + 1))),
    );

    // ---- IDs ----
    final diagnosisEventId = '$caseId-event-diagnosis';
    final imagingEventId = '$caseId-event-imaging';
    final treatmentEventId = '$caseId-event-treatment';
    final labEventId = '$caseId-event-lab';

    final histologyFieldId = '$caseId-field-histology';
    final stageFieldId = '$caseId-field-stage';
    final regimenFieldId = '$caseId-field-regimen';
    final ecogFieldId = '$caseId-field-ecog';
    final liverFieldId = '$caseId-field-liver';
    final biomarkerFieldId = '$caseId-field-biomarker';

    final pathologyEvidenceId = '$caseId-evidence-pathology';
    final imagingEvidenceId = '$caseId-evidence-imaging';
    final orderEvidenceId = '$caseId-evidence-order';
    final labEvidenceId = '$caseId-evidence-lab';

    final blockingFields = <String>[
      if (baseStatus == ScreeningStatus.notReady) 'ECOG评分',
      if (baseStatus == ScreeningStatus.notReady) '当前方案',
    ];
    final reminderFields = <String>[
      if (baseStatus == ScreeningStatus.partial) '关键分子标志物',
      if (baseStatus == ScreeningStatus.partial) '转移部位',
    ];
    final crfBlockingFields = _missingCrfLabels(
      crfTemplate,
      crfValues,
      RequiredLevel.blocking,
    ).where((label) => !blockingFields.contains(label)).toList(growable: false);
    final crfReminderFields = _missingCrfLabels(
      crfTemplate,
      crfValues,
      RequiredLevel.recommended,
    ).where((label) => !reminderFields.contains(label)).toList(growable: false);

    final tasks = <CompletenessTask>[
      if (blockingFields.isNotEmpty)
        CompletenessTask(
          id: '$caseId-task-missing-blocking',
          caseId: caseId,
          title: '补齐核心筛查字段',
          type: TaskType.missingField,
          description: '当前病例仍缺少阻断型字段，无法进入"小丫筛查"。',
          fields: blockingFields,
          owner: '录入用户',
          dueLabel: '今日内',
          isBlocking: true,
        ),
      if (crfBlockingFields.isNotEmpty)
        CompletenessTask(
          id: '$caseId-task-crf-blocking',
          caseId: caseId,
          title: '补齐专病 CRF 阻断字段',
          type: TaskType.missingField,
          description: '当前病例绑定 ${crfTemplate.title}，仍缺少专病阻断字段。',
          fields: crfBlockingFields,
          templateId: crfTemplate.id,
          scope: TaskScope.crf,
          owner: '项目秘书',
          dueLabel: '今日内',
          isBlocking: true,
        ),
      if (reminderFields.isNotEmpty)
        CompletenessTask(
          id: '$caseId-task-missing-reminder',
          caseId: caseId,
          title: '完善提醒字段',
          type: TaskType.missingField,
          description: '建议补齐项目筛查所需的提醒字段，提升快照完整度。',
          fields: reminderFields,
          owner: '项目秘书',
          dueLabel: '24 小时',
        ),
      if (crfReminderFields.isNotEmpty)
        CompletenessTask(
          id: '$caseId-task-crf-reminder',
          caseId: caseId,
          title: '完善专病 CRF 推荐字段',
          type: TaskType.missingField,
          description: '补齐模板推荐字段后，专病筛选命中原因会更完整。',
          fields: crfReminderFields,
          templateId: crfTemplate.id,
          scope: TaskScope.crf,
          owner: '项目秘书',
          dueLabel: '24 小时',
        ),
      if (hasConflict)
        CompletenessTask(
          id: '$caseId-task-conflict',
          caseId: caseId,
          title: '核对 ECOG 冲突',
          type: TaskType.conflictReview,
          description: '病程记录与随访表存在 ECOG 不一致，需要人工确认。',
          fields: const <String>['ECOG评分'],
          fieldCode: 'gu.admission.ecog',
          fieldPath: const <String>['入院记录', '体力状态', 'ECOG评分'],
          templateId: crfTemplate.id,
          scope: TaskScope.canonical,
          conflicts: <ConflictEntry>[
            ConflictEntry(
              field: 'ECOG评分',
              sourceA: '病程记录',
              valueA: '${ecog + 1}',
              sourceB: '随访表',
              valueB: '$ecog',
            ),
          ],
          owner: '随访护士',
          dueLabel: '尽快',
        ),
    ];

    // ---- Structured fields (unchanged) ----
    final structuredFields = <StructuredField>[
      StructuredField(
        id: histologyFieldId,
        label: '病理类型',
        value: histologies[slot],
        group: '诊断',
        confidence: FieldConfidence.verified,
        eventId: diagnosisEventId,
        evidenceId: pathologyEvidenceId,
        isRequired: true,
      ),
      StructuredField(
        id: stageFieldId,
        label: '临床分期',
        value: stages[slot],
        group: '分期',
        confidence: hasConflict
            ? FieldConfidence.aiMedium
            : FieldConfidence.aiHigh,
        eventId: imagingEventId,
        evidenceId: imagingEvidenceId,
        isRequired: true,
      ),
      StructuredField(
        id: regimenFieldId,
        label: '当前方案',
        value: blockingFields.contains('当前方案') ? '待补录' : regimens[slot],
        group: '治疗',
        confidence: blockingFields.contains('当前方案')
            ? FieldConfidence.missing
            : FieldConfidence.aiHigh,
        eventId: treatmentEventId,
        evidenceId: orderEvidenceId,
        isRequired: true,
        isBlocking: true,
      ),
      StructuredField(
        id: ecogFieldId,
        label: 'ECOG评分',
        value: blockingFields.contains('ECOG评分') ? '待补录' : '$ecog',
        group: '筛查',
        confidence: hasConflict
            ? FieldConfidence.conflict
            : blockingFields.contains('ECOG评分')
            ? FieldConfidence.missing
            : FieldConfidence.aiMedium,
        eventId: labEventId,
        evidenceId: labEvidenceId,
        isRequired: true,
        isBlocking: true,
      ),
      StructuredField(
        id: liverFieldId,
        label: '肝功状态',
        value: liverRisk ? 'ALT Grade 2' : '近期稳定',
        group: '安全性',
        confidence: liverRisk
            ? FieldConfidence.aiMedium
            : FieldConfidence.aiHigh,
        eventId: labEventId,
        evidenceId: labEvidenceId,
      ),
      StructuredField(
        id: biomarkerFieldId,
        label: '关键分子标志物',
        value: reminderFields.contains('关键分子标志物')
            ? '待补录'
            : biomarkerLabels[slot],
        group: '标志物',
        confidence: reminderFields.contains('关键分子标志物')
            ? FieldConfidence.missing
            : FieldConfidence.aiHigh,
        eventId: diagnosisEventId,
        evidenceId: pathologyEvidenceId,
      ),
    ];

    // ---- Timeline (unchanged) ----
    final timeline = <TimelineEvent>[
      TimelineEvent(
        id: diagnosisEventId,
        title: '首次确诊',
        subtitle: summary.tumorType,
        dateLabel: conciseDate(now.subtract(Duration(days: 280 + index * 3))),
        type: TimelineEventType.diagnosis,
        description: '完成初次病理判读并建立病例档案。',
        fieldIds: <String>[histologyFieldId, biomarkerFieldId],
        evidenceIds: <String>[pathologyEvidenceId],
        isImportant: true,
      ),
      TimelineEvent(
        id: imagingEventId,
        title: '基线影像',
        subtitle: '${summary.primarySite}病灶评估',
        dateLabel: conciseDate(now.subtract(Duration(days: 240 + index * 2))),
        type: TimelineEventType.imaging,
        description: '形成基线影像结论并确认临床分期。',
        fieldIds: <String>[stageFieldId],
        evidenceIds: <String>[imagingEvidenceId],
      ),
      TimelineEvent(
        id: treatmentEventId,
        title: '当前治疗方案',
        subtitle: '${summary.lineOfTherapy} 线治疗',
        dateLabel: conciseDate(now.subtract(Duration(days: 120 - index))),
        type: TimelineEventType.treatment,
        description: '持续记录当前治疗方案、周期与变更原因。',
        fieldIds: <String>[regimenFieldId],
        evidenceIds: <String>[orderEvidenceId],
        isImportant: true,
      ),
      TimelineEvent(
        id: labEventId,
        title: '近期安全性评估',
        subtitle: liverRisk ? '出现肝功异常' : '实验室指标稳定',
        dateLabel: conciseDate(now.subtract(Duration(days: (index % 7) + 1))),
        type: TimelineEventType.lab,
        description: '用于筛查快照的最新实验室与体能状态。',
        fieldIds: <String>[ecogFieldId, liverFieldId],
        evidenceIds: <String>[labEvidenceId],
      ),
    ];

    // ---- Evidence documents (unchanged) ----
    final evidenceDocuments = <EvidenceDocument>[
      EvidenceDocument(
        id: pathologyEvidenceId,
        title: '病理报告',
        modality: DocumentModality.pdf,
        source: '外院上传',
        dateLabel: conciseDate(now.subtract(Duration(days: 280 + index * 3))),
        summary: '病理诊断明确，含关键免疫组化与标志物描述。',
        anchor: EvidenceAnchor(
          label: '病理诊断段',
          locator: '第 1 页 · 框 02',
          excerpt: '${histologies[slot]}，提示 ${biomarkerLabels[slot]}。',
        ),
        linkedFieldIds: <String>[histologyFieldId, biomarkerFieldId],
        eventId: diagnosisEventId,
      ),
      EvidenceDocument(
        id: imagingEvidenceId,
        title: '基线影像报告',
        modality: DocumentModality.pdf,
        source: '影像中心',
        dateLabel: conciseDate(now.subtract(Duration(days: 240 + index * 2))),
        summary: '完成胸腹盆增强评估，形成 RECIST 基线。',
        anchor: EvidenceAnchor(
          label: '影像结论',
          locator: '第 2 页 · 框 01',
          excerpt: '考虑 ${summary.stage}，病灶大小较前增大。',
        ),
        linkedFieldIds: <String>[stageFieldId],
        eventId: imagingEventId,
      ),
      EvidenceDocument(
        id: orderEvidenceId,
        title: '治疗医嘱与病程摘要',
        modality: DocumentModality.image,
        source: '病区拍照',
        dateLabel: conciseDate(now.subtract(Duration(days: 120 - index))),
        summary: '抽取当前治疗方案、线数及最近一次给药日期。',
        anchor: EvidenceAnchor(
          label: '医嘱截图',
          locator: '图片 1 · 框 05',
          excerpt: '当前方案：${regimens[slot]}。',
        ),
        linkedFieldIds: <String>[regimenFieldId],
        eventId: treatmentEventId,
      ),
      EvidenceDocument(
        id: labEvidenceId,
        title: '近期化验与随访',
        modality: DocumentModality.text,
        source: '结构化录入',
        dateLabel: conciseDate(now.subtract(Duration(days: (index % 7) + 1))),
        summary: '包含 ECOG、肝功能及筛查回填记录。',
        anchor: EvidenceAnchor(
          label: '实验室摘要',
          locator: '时间点 T${(index % 4) + 1}',
          excerpt: liverRisk ? 'ALT 升高，建议复核免疫相关肝损伤。' : '近期 ALT / AST 稳定。',
        ),
        linkedFieldIds: <String>[ecogFieldId, liverFieldId],
        eventId: labEventId,
      ),
    ];

    final alerts = <String>[
      if (liverRisk) '近期 ALT/AST 异常，建议结合免疫治疗安全性复核。',
      if (screeningStatus != ScreeningStatus.ready) '筛查快照存在缺字段，请在提交前完成补录。',
      if (hasConflict) 'ECOG 来源冲突，当前结果仅用于演示。',
    ];

    // ---- New structured data ----
    final diagnosisInfo = DiagnosisInfo(
      primarySiteCode: _primarySiteCodes[slot],
      icd10Code: _icd10Codes[slot],
      pathologyDiagnosis: _pathDiagnoses[slot],
      stageSystem: _stageSystems[slot],
      tnmT: _tnmTs[slot],
      tnmN: _tnmNs[slot],
      tnmM: _tnmMs[slot],
      ajccStage: _ajccStages[slot],
    );

    final treatmentLines = _treatmentLinesForSlot(slot, line, now);

    final labDate = now.subtract(Duration(days: (index % 7) + 1));
    final labPanels = <LabPanel>[
      _labPanel(labDate, liverRisk),
      _labPanel(labDate.subtract(const Duration(days: 14)), false),
    ];

    final weight = 55.0 + (index % 15) * 2.5;
    final hbvSlots = {5, 6};
    final hasHbv = hbvSlots.contains(slot) || index == 11;

    final detail = CaseDetail(
      summary: summary,
      birthYear: 1970 + (index % 20),
      sex: index.isEven ? '女' : '男',
      diagnosisDate: conciseDate(now.subtract(Duration(days: 290 + index * 3))),
      diseaseStatus: diseaseStatuses[slot],
      metastaticSites: reminderFields.contains('转移部位')
          ? '待补录'
          : (index.isEven ? '肺门、纵隔淋巴结' : '肝、腹膜'),
      comorbidities: comorbiditySets[slot],
      alerts: alerts,
      timeline: timeline,
      structuredFields: structuredFields,
      evidenceDocuments: evidenceDocuments,
      diseaseProfile: diseaseProfile,
      crfTemplate: crfTemplate,
      crfValues: crfValues,
      diagnosis: diagnosisInfo,
      molecularResults: reminderFields.contains('关键分子标志物')
          ? const <MolecularResult>[]
          : molecularSets[slot],
      biomarkers: reminderFields.contains('关键分子标志物')
          ? const <BiomarkerResult>[]
          : _biomarkerSets[slot],
      treatmentLines: blockingFields.contains('当前方案')
          ? const <TreatmentLine>[]
          : treatmentLines,
      labPanels: labPanels,
      imagingRecords: _imagingForSlot(slot, now),
      adverseEvents: _adverseEventsForCase(index, slot, liverRisk, now),
      vitalSigns: VitalSignsInfo(ecog: ecog, weight: weight),
      infectionStatus: hasHbv
          ? InfectionInfo(
              hbvStatus: slot == 6 ? 'HBsAg 阳性，抗病毒治疗中' : 'HBsAg 阴性/HBcAb 阳性',
            )
          : null,
    );

    final screening = ScreeningSnapshot(
      caseId: caseId,
      projectTitle: 'YABY 小丫筛查快照',
      status: screeningStatus,
      keyFacts: <String>[
        '${summary.primarySite} · ${summary.stage}',
        '${summary.lineOfTherapy} 线 · ${summary.currentRegimen}',
        blockingFields.contains('ECOG评分') ? 'ECOG 待评估' : 'ECOG ${summary.ecog}',
        liverRisk ? '伴肝功异常' : '肝功稳定',
      ],
      blockingFields: <String>[...blockingFields, ...crfBlockingFields],
      reminderFields: <String>[...reminderFields, ...crfReminderFields],
      tasks: tasks,
      coreCompletionRate: _coreCompletionRate(blockingFields, reminderFields),
      crfCompletionRate: crfCompleteness.rate,
      crfTemplateLabel: '${diseaseProfile.groupCode} ${crfTemplate.version}',
    );

    return MockCaseBundle(detail: detail, screening: screening);
  });
}

List<String> _missingCrfLabels(
  CRFTemplate crfTemplate,
  List<CaseCRFValue> crfValues,
  RequiredLevel requiredLevel,
) {
  final valuesByCode = {for (final value in crfValues) value.fieldCode: value};
  return crfTemplate.fields
      .where((field) => field.requiredLevel == requiredLevel)
      .where((field) => !field.needsGovernance)
      .where((field) {
        final value = valuesByCode[field.fieldCode];
        return value == null || !value.isComplete;
      })
      .map((field) => field.label)
      .toSet()
      .toList(growable: false);
}

double _coreCompletionRate(
  List<String> blockingFields,
  List<String> reminderFields,
) {
  const totalCoreFields = 5;
  final missing = blockingFields.length + reminderFields.length;
  return ((totalCoreFields - missing).clamp(0, totalCoreFields)) /
      totalCoreFields;
}

// ---------------------------------------------------------------------------
// Upload Jobs (unchanged)
// ---------------------------------------------------------------------------

List<UploadJob> buildSeedUploadJobs() {
  return const <UploadJob>[
    UploadJob(
      id: 'upload-001',
      patientId: 'case-001',
      patientName: '吴女士',
      documentType: '病理报告',
      source: UploadSource.pdf,
      stage: UploadJobStage.processing,
      createdAtLabel: '2026-04-14 09:20',
      description: '新增外院病理 PDF，等待 OCR + 结构化抽取。',
      extractedHighlights: <String>[],
      pendingReviewFields: <String>[],
    ),
    UploadJob(
      id: 'upload-002',
      patientId: 'case-002',
      patientName: '赵先生',
      documentType: '随访语音',
      source: UploadSource.voice,
      stage: UploadJobStage.needsReview,
      createdAtLabel: '2026-04-14 08:10',
      description: '语音转写已完成，待确认 ECOG 与不良事件。',
      extractedHighlights: <String>['识别出 ECOG 1', '识别出 ALT 升高'],
      pendingReviewFields: <String>['ECOG评分', '肝功状态'],
    ),
  ];
}
