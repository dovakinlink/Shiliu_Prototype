-- =============================================================================
-- 石榴病例库 - 码表初始化（seed_codesets.sql）
-- =============================================================================
-- 依赖：shiliu_schema.sql 已执行完成。
-- 用法：mysql -u <user> -p <db> < seed_codesets.sql
-- 幂等：所有码表使用 INSERT IGNORE，可重复执行。
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- 1) 码表元信息（code_set）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_set` (`code`, `name`, `source`, `description`) VALUES
  ('DocType',          '文档类型',          'self',    '原始资料类型字典：检验/影像/病理/出院小结等'),
  ('Modality',         '资料模态',          'self',    'L0 资料模态：图片/PDF/语音/视频/文本'),
  ('DrugClass',        '药物大类',          'ATC',     '药物分类：PD-1 / PD-L1 / TKI / 化疗等'),
  ('RegimenType',      '治疗方案类型',      'self',    '一线/二线常用方案分类'),
  ('EventType',        '临床事件类型',      'self',    '时间线事件分类：诊断/手术/影像/检验/AE/随访等'),
  ('ChangeReason',     '剂量调整原因',      'self',    '减量/暂停/停药原因'),
  ('Comorbidity',      '共病',              'ICD10',   '常见基础病字典'),
  ('Tag',              '病例标签',          'self',    '系统/AI 给病例打的标签'),
  ('CTCAE',            '不良事件分级',      'CTCAEv5', 'CTCAE v5.0 常用条目'),
  ('RECIST',           'RECIST 评效',       'RECIST1.1','疗效评估字典'),
  ('AJCC',             'AJCC 分期体系',     'AJCC8',   '分期版本字典'),
  ('PHIClass',         'PHI 字段分级',      'self',    '隐私字段敏感度分级'),
  ('TumorGroup',       '瘤种分组',          'self',    '泌尿/肺/乳腺/消化/妇科/罕见'),
  ('SampleType',       '样本类型',          'self',    '组织/血液/ctDNA/尿液'),
  ('FollowUpMethod',   '随访方式',          'self',    '电话/门诊/线上/微信'),
  ('LabTestStd',       '常用检验项',        'LOINC',   'ALT/AST/TBil/Cr/ANC/PLT/HGB...'),
  ('Biomarker',        '生物标志物',        'self',    'PD-L1/MSI/TMB/HER2/Ki67/CPS'),
  ('TaskType',         '完整性任务类型',    'self',    '缺字段/冲突/治理/模板迁移'),
  ('CaseRole',         '系统角色',          'self',    '医生/秘书/管理员/AI 服务'),
  ('UploadSource',     '上传来源',          'self',    '相机/PDF/语音/相册/API');

-- -----------------------------------------------------------------------------
-- 2) DocType
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'lab_report'        AS code, '检验报告'      AS label,  10 AS sort_order UNION ALL
  SELECT 'imaging_report',          '影像报告',                  20 UNION ALL
  SELECT 'pathology_report',        '病理报告',                  30 UNION ALL
  SELECT 'discharge_summary',       '出院小结',                  40 UNION ALL
  SELECT 'clinic_note',             '门诊病历',                  50 UNION ALL
  SELECT 'admission_note',          '入院记录',                  60 UNION ALL
  SELECT 'progress_note',           '病程记录',                  70 UNION ALL
  SELECT 'operation_note',          '手术记录',                  80 UNION ALL
  SELECT 'molecular_report',        '基因检测报告',              90 UNION ALL
  SELECT 'consent',                 '知情同意书',               100 UNION ALL
  SELECT 'voice_dictation',         '语音口述',                 110 UNION ALL
  SELECT 'wechat_chat',             '微信对话截图',             120 UNION ALL
  SELECT 'external_text',           '外部文本',                 130 UNION ALL
  SELECT 'unknown',                 '未识别',                   999
) t ON cs.code = 'DocType';

-- -----------------------------------------------------------------------------
-- 3) Modality
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'IMG'   AS code, '图片'  AS label, 10 AS sort_order UNION ALL
  SELECT 'PDF',           'PDF',          20 UNION ALL
  SELECT 'AUDIO',         '语音',         30 UNION ALL
  SELECT 'VIDEO',         '视频',         40 UNION ALL
  SELECT 'TEXT',          '文本',         50
) t ON cs.code = 'Modality';

-- -----------------------------------------------------------------------------
-- 4) DrugClass（含 ATC 提示，便于映射）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'PD1'              AS code, 'PD-1 抑制剂'           AS label,  10 AS sort_order, JSON_OBJECT('atc','L01FF')   AS extra UNION ALL
  SELECT 'PDL1',                     'PD-L1 抑制剂',                    20,             JSON_OBJECT('atc','L01FF')          UNION ALL
  SELECT 'CTLA4',                    'CTLA-4 抑制剂',                   30,             JSON_OBJECT('atc','L01FX')          UNION ALL
  SELECT 'TKI_VEGFR',                'VEGFR-TKI',                       40,             JSON_OBJECT('atc','L01EK')          UNION ALL
  SELECT 'TKI_EGFR',                 'EGFR-TKI',                        50,             JSON_OBJECT('atc','L01EB')          UNION ALL
  SELECT 'TKI_ALK',                  'ALK 抑制剂',                      60,             JSON_OBJECT('atc','L01ED')          UNION ALL
  SELECT 'TKI_BRAF',                 'BRAF 抑制剂',                     70,             JSON_OBJECT('atc','L01EC')          UNION ALL
  SELECT 'TKI_HER2',                 'HER2-TKI',                        80,             JSON_OBJECT('atc','L01EH')          UNION ALL
  SELECT 'CHEMO_PLATINUM',           '铂类化疗',                        90,             JSON_OBJECT('atc','L01XA')          UNION ALL
  SELECT 'CHEMO_TAXANE',             '紫杉类',                         100,             JSON_OBJECT('atc','L01CD')          UNION ALL
  SELECT 'CHEMO_ANTIMETABOLITE',     '抗代谢类',                       110,             JSON_OBJECT('atc','L01B')           UNION ALL
  SELECT 'CHEMO_GEMCITABINE',        '吉西他滨',                       120,             JSON_OBJECT('atc','L01BC05')        UNION ALL
  SELECT 'ADC_HER2',                 'HER2 ADC',                       130,             JSON_OBJECT('atc','L01FD')          UNION ALL
  SELECT 'ADC_NECTIN4',              'Nectin-4 ADC',                   140,             JSON_OBJECT('atc','L01FX')          UNION ALL
  SELECT 'ADC_TROP2',                'TROP2 ADC',                      150,             JSON_OBJECT('atc','L01FX')          UNION ALL
  SELECT 'PARP',                     'PARP 抑制剂',                    160,             JSON_OBJECT('atc','L01XK')          UNION ALL
  SELECT 'CDK46',                    'CDK4/6 抑制剂',                  170,             JSON_OBJECT('atc','L01EF')          UNION ALL
  SELECT 'HORMONE_AR',               'AR 拮抗剂',                      180,             JSON_OBJECT('atc','L02BB')          UNION ALL
  SELECT 'HORMONE_GNRH',             'GnRH 类似物',                    190,             JSON_OBJECT('atc','L02AE')          UNION ALL
  SELECT 'BCG',                      '膀胱灌注 BCG',                   200,             JSON_OBJECT('atc','L03AX03')        UNION ALL
  SELECT 'CHEMO_OTHER',              '其他化疗药物',                   900,             NULL                                UNION ALL
  SELECT 'TARGET_OTHER',             '其他靶向',                       910,             NULL                                UNION ALL
  SELECT 'OTHER',                    '其他',                           999,             NULL
) t ON cs.code = 'DrugClass';

-- -----------------------------------------------------------------------------
-- 5) RegimenType
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'IO_MONO'        AS code, 'IO 单药'         AS label, 10 AS sort_order UNION ALL
  SELECT 'IO_DOUBLET',             '双免联合',                20 UNION ALL
  SELECT 'CHEMO_IO',               '化疗 + 免疫',             30 UNION ALL
  SELECT 'CHEMO_ONLY',             '单纯化疗',                40 UNION ALL
  SELECT 'TKI_MONO',               'TKI 单药',                50 UNION ALL
  SELECT 'TKI_IO',                 'TKI + 免疫',              60 UNION ALL
  SELECT 'ADC_IO',                 'ADC + 免疫',              70 UNION ALL
  SELECT 'ADC_MONO',               'ADC 单药',                80 UNION ALL
  SELECT 'TARGET_MONO',            '靶向单药',                90 UNION ALL
  SELECT 'CHEMO_TARGET',           '化疗 + 靶向',            100 UNION ALL
  SELECT 'HORMONE_THERAPY',        '内分泌治疗',             110 UNION ALL
  SELECT 'BCG_INSTILLATION',       '膀胱灌注治疗',           120 UNION ALL
  SELECT 'BSC',                    '最佳支持治疗',           200 UNION ALL
  SELECT 'CLINICAL_TRIAL',         '临床试验方案',           300 UNION ALL
  SELECT 'OTHER',                  '其他',                   999
) t ON cs.code = 'RegimenType';

-- -----------------------------------------------------------------------------
-- 6) EventType
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'diagnosis'          AS code, '诊断'          AS label,  10 AS sort_order UNION ALL
  SELECT 'staging',                    '分期评估',               20 UNION ALL
  SELECT 'molecular_test',             '基因检测',               30 UNION ALL
  SELECT 'biomarker_test',             '免疫指标检测',           40 UNION ALL
  SELECT 'surgery',                    '手术',                   50 UNION ALL
  SELECT 'radiotherapy',               '放疗',                   60 UNION ALL
  SELECT 'systemic_therapy',           '系统治疗',               70 UNION ALL
  SELECT 'regimen_start',              '治疗方案开始',           71 UNION ALL
  SELECT 'regimen_change',             '方案变更',               72 UNION ALL
  SELECT 'dose_adjust',                '剂量调整',               73 UNION ALL
  SELECT 'imaging',                    '影像检查',               80 UNION ALL
  SELECT 'lab',                        '检验',                   90 UNION ALL
  SELECT 'response_eval',              '疗效评估',              100 UNION ALL
  SELECT 'progression',                '疾病进展',              110 UNION ALL
  SELECT 'adverse_event',              '不良事件',              120 UNION ALL
  SELECT 'hospitalization',            '住院',                  130 UNION ALL
  SELECT 'follow_up',                  '随访',                  140 UNION ALL
  SELECT 'death',                      '死亡',                  150 UNION ALL
  SELECT 'lost_followup',              '失访',                  160 UNION ALL
  SELECT 'mdt',                        'MDT 讨论',              170 UNION ALL
  SELECT 'consent',                    '知情签署',              180 UNION ALL
  SELECT 'screening',                  '入组筛查',              190 UNION ALL
  SELECT 'note',                       '备注',                  900
) t ON cs.code = 'EventType';

-- -----------------------------------------------------------------------------
-- 7) ChangeReason（剂量调整 / 停药原因）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'AE_HEPATITIS'   AS code, '肝功能异常'        AS label, 10 AS sort_order UNION ALL
  SELECT 'AE_HEMATOLOGY',          '骨髓抑制',                  20 UNION ALL
  SELECT 'AE_RENAL',               '肾功能损伤',                30 UNION ALL
  SELECT 'AE_NEURO',               '神经系统毒性',              40 UNION ALL
  SELECT 'AE_GI',                  '消化道反应',                50 UNION ALL
  SELECT 'AE_SKIN',                '皮肤毒性',                  60 UNION ALL
  SELECT 'AE_IRAE',                '免疫相关 AE',               70 UNION ALL
  SELECT 'AE_INFECTION',           '感染',                      80 UNION ALL
  SELECT 'AE_OTHER',               '其他不良事件',              90 UNION ALL
  SELECT 'PROGRESSION',            '疾病进展',                 100 UNION ALL
  SELECT 'PATIENT_REQUEST',        '患者要求',                 110 UNION ALL
  SELECT 'COST',                   '费用因素',                 120 UNION ALL
  SELECT 'COMPLETED',              '完成既定疗程',             130 UNION ALL
  SELECT 'OTHER',                  '其他',                     999
) t ON cs.code = 'ChangeReason';

-- -----------------------------------------------------------------------------
-- 8) Comorbidity（常见基础病）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'HTN'        AS code, '高血压'      AS label, 10 AS sort_order, JSON_OBJECT('icd10','I10') AS extra UNION ALL
  SELECT 'DM',                 '糖尿病',              20,                JSON_OBJECT('icd10','E11')          UNION ALL
  SELECT 'CHD',                '冠心病',              30,                JSON_OBJECT('icd10','I25')          UNION ALL
  SELECT 'COPD',               '慢阻肺',              40,                JSON_OBJECT('icd10','J44')          UNION ALL
  SELECT 'ASTHMA',             '哮喘',                50,                JSON_OBJECT('icd10','J45')          UNION ALL
  SELECT 'CKD',                '慢性肾病',            60,                JSON_OBJECT('icd10','N18')          UNION ALL
  SELECT 'CLD',                '慢性肝病',            70,                JSON_OBJECT('icd10','K76')          UNION ALL
  SELECT 'HBV_CHRONIC',        '慢性乙肝',            71,                JSON_OBJECT('icd10','B18.1')        UNION ALL
  SELECT 'HCV_CHRONIC',        '慢性丙肝',            72,                JSON_OBJECT('icd10','B18.2')        UNION ALL
  SELECT 'STROKE',             '脑卒中史',            80,                JSON_OBJECT('icd10','I64')          UNION ALL
  SELECT 'AUTOIMMUNE',         '自身免疫病',          90,                JSON_OBJECT('icd10','M35')          UNION ALL
  SELECT 'THYROID',            '甲状腺疾病',         100,                NULL                                UNION ALL
  SELECT 'TB',                 '结核',               110,                JSON_OBJECT('icd10','A15')          UNION ALL
  SELECT 'HIV',                'HIV 感染',           120,                JSON_OBJECT('icd10','B20')          UNION ALL
  SELECT 'PSYCH',              '精神疾病',           130,                NULL                                UNION ALL
  SELECT 'OTHER',              '其他',               999,                NULL
) t ON cs.code = 'Comorbidity';

-- -----------------------------------------------------------------------------
-- 9) Tag（病例标签）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'GU'                AS code, '泌尿生殖'        AS label,  10 AS sort_order, JSON_OBJECT('color','#3B82F6') AS extra UNION ALL
  SELECT 'LUNG',                      '肺癌',                       20,                JSON_OBJECT('color','#10B981')          UNION ALL
  SELECT 'GI',                        '消化道',                     30,                JSON_OBJECT('color','#F59E0B')          UNION ALL
  SELECT 'BREAST',                    '乳腺',                       40,                JSON_OBJECT('color','#EC4899')          UNION ALL
  SELECT 'GYN',                       '妇科',                       50,                JSON_OBJECT('color','#A855F7')          UNION ALL
  SELECT 'STAGE_IV',                  'IV 期',                      60,                JSON_OBJECT('color','#EF4444')          UNION ALL
  SELECT 'METASTATIC',                '转移',                       70,                JSON_OBJECT('color','#EF4444')          UNION ALL
  SELECT 'LIVER_RISK',                '肝功能风险',                 80,                JSON_OBJECT('color','#F59E0B')          UNION ALL
  SELECT 'IRAE_HISTORY',              'irAE 既往',                  90,                JSON_OBJECT('color','#F97316')          UNION ALL
  SELECT 'BIOMARKER_POS',             '标志物阳性',                100,                JSON_OBJECT('color','#22C55E')          UNION ALL
  SELECT 'TRIAL_CANDIDATE',           '入组候选',                  110,                JSON_OBJECT('color','#0EA5E9')          UNION ALL
  SELECT 'NEEDS_REVIEW',              '待审核',                    120,                JSON_OBJECT('color','#6B7280')          UNION ALL
  SELECT 'CONFLICT',                  '存在冲突',                  130,                JSON_OBJECT('color','#DC2626')          UNION ALL
  SELECT 'COMPLETE',                  '齐全',                      140,                JSON_OBJECT('color','#16A34A')          UNION ALL
  SELECT 'BLOCKING_MISSING',          '关键缺失',                  150,                JSON_OBJECT('color','#DC2626')
) t ON cs.code = 'Tag';

-- -----------------------------------------------------------------------------
-- 10) CTCAE（仅常用条目，业务侧按需扩展）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'ALT_INCREASE'      AS code, 'ALT 升高'         AS label,  10 AS sort_order UNION ALL
  SELECT 'AST_INCREASE',              'AST 升高',                  20 UNION ALL
  SELECT 'TBIL_INCREASE',             '总胆红素升高',              30 UNION ALL
  SELECT 'CR_INCREASE',               '肌酐升高',                  40 UNION ALL
  SELECT 'NEUTROPHIL_DECREASE',       '中性粒细胞减少',            50 UNION ALL
  SELECT 'PLATELET_DECREASE',         '血小板减少',                60 UNION ALL
  SELECT 'ANEMIA',                    '贫血',                      70 UNION ALL
  SELECT 'PNEUMONITIS',               '免疫相关肺炎',              80 UNION ALL
  SELECT 'COLITIS',                   '免疫相关肠炎',              90 UNION ALL
  SELECT 'HYPOTHYROIDISM',            '甲状腺功能减退',           100 UNION ALL
  SELECT 'HYPERTHYROIDISM',           '甲状腺功能亢进',           110 UNION ALL
  SELECT 'HEPATITIS_IRAE',            '免疫相关肝炎',             120 UNION ALL
  SELECT 'NEPHRITIS_IRAE',            '免疫相关肾炎',             130 UNION ALL
  SELECT 'RASH',                      '皮疹',                     140 UNION ALL
  SELECT 'FATIGUE',                   '乏力',                     150 UNION ALL
  SELECT 'NAUSEA',                    '恶心',                     160 UNION ALL
  SELECT 'VOMITING',                  '呕吐',                     170 UNION ALL
  SELECT 'DIARRHEA',                  '腹泻',                     180 UNION ALL
  SELECT 'FEVER',                     '发热',                     190 UNION ALL
  SELECT 'NEUROPATHY',                '周围神经病',               200
) t ON cs.code = 'CTCAE';

-- -----------------------------------------------------------------------------
-- 11) RECIST
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'CR' AS code, '完全缓解 (CR)' AS label, 10 AS sort_order UNION ALL
  SELECT 'PR',         '部分缓解 (PR)',         20 UNION ALL
  SELECT 'SD',         '疾病稳定 (SD)',         30 UNION ALL
  SELECT 'PD',         '疾病进展 (PD)',         40 UNION ALL
  SELECT 'NE',         '不可评价 (NE)',         50 UNION ALL
  SELECT 'UNKNOWN',    '未评估',                99
) t ON cs.code = 'RECIST';

-- -----------------------------------------------------------------------------
-- 12) AJCC
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'AJCC7'       AS code, 'AJCC 第 7 版' AS label, 10 AS sort_order UNION ALL
  SELECT 'AJCC8',               'AJCC 第 8 版',         20 UNION ALL
  SELECT 'AJCC9',               'AJCC 第 9 版',         30 UNION ALL
  SELECT 'INHOUSE',             '院内分期标准',         40 UNION ALL
  SELECT 'OTHER',               '其他',                 99
) t ON cs.code = 'AJCC';

-- -----------------------------------------------------------------------------
-- 13) PHIClass（PHI 字段分级）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'L0_PUBLIC'   AS code, '公开'           AS label, 10 AS sort_order, JSON_OBJECT('mask','none')        AS extra UNION ALL
  SELECT 'L1_INTERNAL',         '内部',                   20,                JSON_OBJECT('mask','none')               UNION ALL
  SELECT 'L2_RESEARCH',         '科研可见',               30,                JSON_OBJECT('mask','partial')            UNION ALL
  SELECT 'L3_PHI',              'PHI 高敏',               40,                JSON_OBJECT('mask','strict')             UNION ALL
  SELECT 'L4_PII_DIRECT',       '直接身份标识',           50,                JSON_OBJECT('mask','encrypt')
) t ON cs.code = 'PHIClass';

-- -----------------------------------------------------------------------------
-- 14) TumorGroup（瘤种分组，与 disease_profile.group_code 同义）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'GU'       AS code, '泌尿生殖'  AS label, 10 AS sort_order, JSON_OBJECT('color','#3B82F6') AS extra UNION ALL
  SELECT 'LUNG',             '肺癌',              20,                JSON_OBJECT('color','#10B981')          UNION ALL
  SELECT 'BREAST',           '乳腺癌',            30,                JSON_OBJECT('color','#EC4899')          UNION ALL
  SELECT 'GI',               '消化道肿瘤',        40,                JSON_OBJECT('color','#F59E0B')          UNION ALL
  SELECT 'GYN',              '妇科肿瘤',          50,                JSON_OBJECT('color','#A855F7')          UNION ALL
  SELECT 'HEAD_NECK',        '头颈肿瘤',          60,                JSON_OBJECT('color','#0EA5E9')          UNION ALL
  SELECT 'HEPATOBILIARY',    '肝胆胰',            70,                JSON_OBJECT('color','#65A30D')          UNION ALL
  SELECT 'HEMATOLOGY',       '血液系统',          80,                JSON_OBJECT('color','#9333EA')          UNION ALL
  SELECT 'CNS',              '中枢神经系统',      90,                JSON_OBJECT('color','#475569')          UNION ALL
  SELECT 'RARE',             '罕见 / 其他',      100,                JSON_OBJECT('color','#6B7280')
) t ON cs.code = 'TumorGroup';

-- -----------------------------------------------------------------------------
-- 15) SampleType
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'TISSUE'  AS code, '组织样本'      AS label, 10 AS sort_order UNION ALL
  SELECT 'BLOOD',           '血液',                  20 UNION ALL
  SELECT 'ctDNA',           'ctDNA / 液体活检',      30 UNION ALL
  SELECT 'URINE',           '尿液',                  40 UNION ALL
  SELECT 'BMA',             '骨髓',                  50 UNION ALL
  SELECT 'OTHER',           '其他',                  99
) t ON cs.code = 'SampleType';

-- -----------------------------------------------------------------------------
-- 16) FollowUpMethod
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'phone'   AS code, '电话随访'  AS label, 10 AS sort_order UNION ALL
  SELECT 'clinic',          '门诊随访',          20 UNION ALL
  SELECT 'online',          '在线问诊',          30 UNION ALL
  SELECT 'wechat',          '微信沟通',          40 UNION ALL
  SELECT 'sms',             '短信',              50 UNION ALL
  SELECT 'home_visit',      '上门探访',          60 UNION ALL
  SELECT 'other',           '其他',              99
) t ON cs.code = 'FollowUpMethod';

-- -----------------------------------------------------------------------------
-- 17) LabTestStd（常用检验项，含 LOINC 提示）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'ALT'       AS code, 'ALT (谷丙转氨酶)'  AS label,  10 AS sort_order, JSON_OBJECT('loinc','1742-6','unit','U/L')   AS extra UNION ALL
  SELECT 'AST',               'AST (谷草转氨酶)',            20,                JSON_OBJECT('loinc','1920-8','unit','U/L')          UNION ALL
  SELECT 'TBIL',              '总胆红素',                    30,                JSON_OBJECT('loinc','1975-2','unit','umol/L')       UNION ALL
  SELECT 'DBIL',              '直接胆红素',                  40,                JSON_OBJECT('loinc','1968-7','unit','umol/L')       UNION ALL
  SELECT 'ALB',               '白蛋白',                      50,                JSON_OBJECT('loinc','1751-7','unit','g/L')          UNION ALL
  SELECT 'CR',                '肌酐',                        60,                JSON_OBJECT('loinc','2160-0','unit','umol/L')       UNION ALL
  SELECT 'BUN',               '尿素氮',                      70,                JSON_OBJECT('loinc','3094-0','unit','mmol/L')       UNION ALL
  SELECT 'eGFR',              'eGFR',                        80,                JSON_OBJECT('loinc','62238-1','unit','mL/min/1.73m2') UNION ALL
  SELECT 'WBC',               '白细胞',                      90,                JSON_OBJECT('loinc','6690-2','unit','10^9/L')       UNION ALL
  SELECT 'ANC',               '中性粒细胞绝对值',           100,                JSON_OBJECT('loinc','751-8','unit','10^9/L')        UNION ALL
  SELECT 'HGB',               '血红蛋白',                   110,                JSON_OBJECT('loinc','718-7','unit','g/L')           UNION ALL
  SELECT 'PLT',               '血小板',                     120,                JSON_OBJECT('loinc','777-3','unit','10^9/L')        UNION ALL
  SELECT 'LDH',               '乳酸脱氢酶',                 130,                JSON_OBJECT('loinc','2532-0','unit','U/L')          UNION ALL
  SELECT 'CRP',               'C 反应蛋白',                 140,                JSON_OBJECT('loinc','1988-5','unit','mg/L')         UNION ALL
  SELECT 'TSH',               'TSH',                        150,                JSON_OBJECT('loinc','3016-3','unit','mIU/L')        UNION ALL
  SELECT 'FT4',               'FT4',                        160,                JSON_OBJECT('loinc','3024-7','unit','pmol/L')       UNION ALL
  SELECT 'CEA',               'CEA',                        170,                JSON_OBJECT('loinc','2039-6','unit','ng/mL')        UNION ALL
  SELECT 'CA199',             'CA19-9',                     180,                JSON_OBJECT('loinc','24108-3','unit','U/mL')        UNION ALL
  SELECT 'PSA_TOTAL',         'PSA 总',                     190,                JSON_OBJECT('loinc','2857-1','unit','ng/mL')        UNION ALL
  SELECT 'PSA_FREE',          'PSA 游离',                   191,                JSON_OBJECT('loinc','10886-0','unit','ng/mL')       UNION ALL
  SELECT 'AFP',               'AFP',                        200,                JSON_OBJECT('loinc','1834-1','unit','ng/mL')        UNION ALL
  SELECT 'CA125',             'CA125',                      210,                JSON_OBJECT('loinc','10334-1','unit','U/mL')        UNION ALL
  SELECT 'NSE',               'NSE',                        220,                JSON_OBJECT('loinc','19133-6','unit','ng/mL')
) t ON cs.code = 'LabTestStd';

-- -----------------------------------------------------------------------------
-- 18) Biomarker
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`, `extra`)
SELECT cs.id, t.code, t.label, t.sort_order, t.extra FROM `code_set` cs
JOIN (
  SELECT 'PD-L1_TPS'  AS code, 'PD-L1 (TPS)'   AS label,  10 AS sort_order, JSON_OBJECT('unit','%')           AS extra UNION ALL
  SELECT 'PD-L1_CPS',          'PD-L1 (CPS)',             20,                JSON_OBJECT('unit','')                  UNION ALL
  SELECT 'PD-L1_IC',           'PD-L1 (IC)',              30,                JSON_OBJECT('unit','%')                 UNION ALL
  SELECT 'MSI',                'MSI 状态',                40,                JSON_OBJECT('values','MSI-H/MSI-L/MSS')  UNION ALL
  SELECT 'MMR',                'MMR 状态',                50,                JSON_OBJECT('values','dMMR/pMMR')        UNION ALL
  SELECT 'TMB',                'TMB',                     60,                JSON_OBJECT('unit','muts/Mb')           UNION ALL
  SELECT 'HER2_IHC',           'HER2 (IHC)',              70,                JSON_OBJECT('values','0/1+/2+/3+')       UNION ALL
  SELECT 'HER2_FISH',          'HER2 (FISH)',             71,                JSON_OBJECT('values','阳性/阴性')        UNION ALL
  SELECT 'KI67',               'Ki-67',                   80,                JSON_OBJECT('unit','%')                 UNION ALL
  SELECT 'ER',                 '雌激素受体',              90,                JSON_OBJECT('unit','%')                 UNION ALL
  SELECT 'PR',                 '孕激素受体',             100,                JSON_OBJECT('unit','%')                 UNION ALL
  SELECT 'AR',                 '雄激素受体',             110,                NULL                                    UNION ALL
  SELECT 'NECTIN4',            'Nectin-4',                120,                JSON_OBJECT('values','阳性/阴性')        UNION ALL
  SELECT 'TROP2',              'TROP2',                   130,                JSON_OBJECT('values','阳性/阴性')        UNION ALL
  SELECT 'FGFR',               'FGFR 状态',               140,                JSON_OBJECT('values','突变/融合/野生')   UNION ALL
  SELECT 'BRCA',               'BRCA1/2',                 150,                JSON_OBJECT('values','突变/野生')        UNION ALL
  SELECT 'HRD',                'HRD',                     160,                JSON_OBJECT('values','阳性/阴性')
) t ON cs.code = 'Biomarker';

-- -----------------------------------------------------------------------------
-- 19) TaskType
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'missing_field'      AS code, '缺字段补录'    AS label, 10 AS sort_order UNION ALL
  SELECT 'conflict_review',            '冲突核对',              20 UNION ALL
  SELECT 'governance',                 '治理任务',              30 UNION ALL
  SELECT 'template_migration',         '模板版本迁移',          40 UNION ALL
  SELECT 'consent_renewal',            '知情续签',              50 UNION ALL
  SELECT 'data_quality',               '数据质量复核',          60
) t ON cs.code = 'TaskType';

-- -----------------------------------------------------------------------------
-- 20) CaseRole（系统角色）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'doctor'      AS code, '主治医师'        AS label, 10 AS sort_order UNION ALL
  SELECT 'coordinator',         '研究协调员',                20 UNION ALL
  SELECT 'reviewer',            '数据审核员',                30 UNION ALL
  SELECT 'admin',               '系统管理员',                40 UNION ALL
  SELECT 'ai_service',          'AI 服务',                   50 UNION ALL
  SELECT 'guest',               '只读访客',                  60
) t ON cs.code = 'CaseRole';

-- -----------------------------------------------------------------------------
-- 21) UploadSource
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `code_value` (`code_set_id`, `code`, `label`, `sort_order`)
SELECT cs.id, t.code, t.label, t.sort_order FROM `code_set` cs
JOIN (
  SELECT 'camera'  AS code, '相机拍摄'   AS label, 10 AS sort_order UNION ALL
  SELECT 'gallery',         '相册导入',           20 UNION ALL
  SELECT 'pdf',             'PDF 上传',           30 UNION ALL
  SELECT 'voice',           '语音录入',           40 UNION ALL
  SELECT 'wechat',          '微信导入',           50 UNION ALL
  SELECT 'api',             '系统对接',           60
) t ON cs.code = 'UploadSource';

-- -----------------------------------------------------------------------------
-- 22) 默认 disease_profile（与高保真原型对齐）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `disease_profile`
  (`profile_uid`, `group_code`, `group_name`, `tumor_code`, `tumor_name`, `display_color`, `enabled`)
VALUES
  (REPLACE(UUID(),'-',''), 'GU',     '泌尿生殖',     'bladder',  '尿路上皮癌',   '#3B82F6', 1),
  (REPLACE(UUID(),'-',''), 'GU',     '泌尿生殖',     'prostate', '前列腺癌',     '#1D4ED8', 1),
  (REPLACE(UUID(),'-',''), 'GU',     '泌尿生殖',     'renal',    '肾癌',         '#0EA5E9', 1),
  (REPLACE(UUID(),'-',''), 'LUNG',   '肺癌',         'nsclc',    '非小细胞肺癌', '#10B981', 1),
  (REPLACE(UUID(),'-',''), 'LUNG',   '肺癌',         'sclc',     '小细胞肺癌',   '#059669', 1),
  (REPLACE(UUID(),'-',''), 'BREAST', '乳腺癌',       'breast',   '乳腺癌',       '#EC4899', 1),
  (REPLACE(UUID(),'-',''), 'GI',     '消化道肿瘤',   'gastric',  '胃癌',         '#F59E0B', 1),
  (REPLACE(UUID(),'-',''), 'GI',     '消化道肿瘤',   'crc',      '结直肠癌',     '#FB923C', 1),
  (REPLACE(UUID(),'-',''), 'GYN',    '妇科肿瘤',     'ovarian',  '卵巢癌',       '#A855F7', 1),
  (REPLACE(UUID(),'-',''), 'RARE',   '罕见 / 其他', 'other',    '其他',         '#6B7280', 1);

-- -----------------------------------------------------------------------------
-- 23) 内置角色 / 权限（与 CaseRole 对齐）
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO `role` (`code`, `name`, `description`, `is_builtin`) VALUES
  ('doctor',      '主治医师',     '可读写所属病例',                1),
  ('coordinator', '研究协调员',   '可创建/编辑病例、维护任务',     1),
  ('reviewer',    '数据审核员',   '可审核 AI 抽取，回退冲突',      1),
  ('admin',       '系统管理员',   '系统级管理：模板/字典/权限',    1),
  ('ai_service',  'AI 服务',      '后台写入抽取结果',              1),
  ('guest',       '只读访客',     '只读访问受限范围病例',          1);

INSERT IGNORE INTO `permission` (`code`, `name`, `module`, `description`) VALUES
  ('case.read',                  '查看病例',           'case',      '病例只读'),
  ('case.write',                  '编辑病例',           'case',      '编辑病例核心字段'),
  ('case.delete',                 '删除病例',           'case',      '软删除病例'),
  ('case.export',                 '导出病例',           'case',      '脱敏导出'),
  ('case.review',                 '审核病例',           'case',      '审核 AI 抽取/冲突'),
  ('crf.template.read',           '查看 CRF 模板',      'crf',       '查看模板与字段'),
  ('crf.template.edit',           '编辑 CRF 模板',      'crf',       '维护字段/章节/映射'),
  ('crf.template.publish',        '发布 CRF 模板',      'crf',       '发布新版本，归档旧版'),
  ('screening.read',              '查看筛查中心',       'screening', '查看 YABY 与项目状态'),
  ('screening.evaluate',          '执行筛查评估',       'screening', '触发 YABY 重算'),
  ('upload.submit',                '提交上传任务',       'upload',    '采集/上传'),
  ('upload.review',                '审核上传任务',       'upload',    '审核 AI 抽取行'),
  ('admin.user.manage',           '用户管理',           'admin',     '增删用户/角色'),
  ('admin.dict.manage',           '字典管理',           'admin',     '维护码表'),
  ('admin.audit.read',            '查看审计',           'admin',     '审计/日志查询'),
  ('admin.export.review',          '审批导出',           'admin',     '审批科研导出申请');

-- 默认角色-权限关系
INSERT IGNORE INTO `role_permission` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `role` r JOIN `permission` p ON
  (r.code = 'doctor'      AND p.code IN ('case.read','case.write','case.review','crf.template.read','screening.read','screening.evaluate','upload.submit','upload.review'))
  OR (r.code = 'coordinator' AND p.code IN ('case.read','case.write','case.export','crf.template.read','screening.read','screening.evaluate','upload.submit','upload.review'))
  OR (r.code = 'reviewer'    AND p.code IN ('case.read','case.review','crf.template.read','upload.review','admin.audit.read'))
  OR (r.code = 'admin'       AND p.code IN ('case.read','case.write','case.delete','case.export','case.review','crf.template.read','crf.template.edit','crf.template.publish','screening.read','screening.evaluate','upload.submit','upload.review','admin.user.manage','admin.dict.manage','admin.audit.read','admin.export.review'))
  OR (r.code = 'ai_service'  AND p.code IN ('case.read','case.write','upload.submit'))
  OR (r.code = 'guest'       AND p.code IN ('case.read','crf.template.read','screening.read'));

-- =============================================================================
-- 完成。
-- 后续如需扩展字典：
--   1. 先 INSERT INTO code_set 注册码表；
--   2. 再 INSERT INTO code_value 添加码值；
--   3. 如有 OCR 同义词，写入 code_value_alias。
-- =============================================================================
