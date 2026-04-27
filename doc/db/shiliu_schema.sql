-- =============================================================================
-- 石榴病例库（Shiliu Case Library） - MySQL 8.0 数据库 Schema
-- =============================================================================
-- 版本：v0.1
-- 数据库：MySQL 8.0+ (utf8mb4_0900_ai_ci)
-- 部署模式：单租户单库
-- 配套文件：seed_codesets.sql（码表初始化数据）
--
-- 设计来源：
--   - doc/数据字典.txt（L0/L1/L2/L3/L4 字段主干）
--   - doc/多瘤种高保真APP改造方案.md（CRF 模板配置化方案）
--   - lib/features/* 高保真原型领域模型
--
-- -----------------------------------------------------------------------------
-- 全局命名 / 约定
-- -----------------------------------------------------------------------------
-- 1. 命名规范
--    表名、字段名一律 snake_case，不使用复数；关系表用 `主表_关联表` 命名。
--    主键统一为 id BIGINT UNSIGNED AUTO_INCREMENT；面向外部稳定标识使用
--    {entity}_uid CHAR(32)（建议 UUIDv7 去除连字符）唯一索引。
--
-- 2. 通用字段（每张业务表必带）
--    - id              主键
--    - created_at      创建时间，默认 CURRENT_TIMESTAMP(3)
--    - updated_at      更新时间，ON UPDATE CURRENT_TIMESTAMP(3)
--    - created_by      创建人 user.id，可空（系统/AI 写入时可为空）
--    - updated_by      最后修改人 user.id，可空
--    业务实体表追加：
--    - deleted_at      软删除时间，NULL 表示有效
--    字典表 / 审计表 / 日志表不软删。
--
-- 3. 软删除 + 唯一约束的处理
--    MySQL UNIQUE 允许多个 NULL，单纯使用 (col, deleted_at) 不能保证活动行
--    唯一性。在需要"软删后允许重建"的表上统一新增一列：
--      deleted_marker BIGINT UNSIGNED NOT NULL DEFAULT 0
--    然后唯一索引建在 (业务键, deleted_marker)。
--    应用层规范（必须严格遵守）：
--      - 创建/更新活动行时：deleted_at = NULL, deleted_marker = 0。
--      - 软删除时：UPDATE 表 SET deleted_at = NOW(3),
--                deleted_marker = ROUND(UNIX_TIMESTAMP(NOW(3)) * 1000)。
--    （未使用 GENERATED ALWAYS，因为 UNIX_TIMESTAMP(DATETIME) 在 MySQL 8.0
--      STORED 生成列下被视为非确定性函数会报错。）
--
-- 4. 枚举策略
--    - 使用 MySQL ENUM 的场景：取值稳定且跨表统一，如 modality、status、
--      required_level、screening_status、confidence、change_type 等。
--    - 使用字典表（code_set + code_value）的场景：业务可扩展、需要前端配置
--      的码表，如 doc_type、drug_class、event_type、tag、ctcae 等。
--
-- 5. JSON 字段使用约束（仅用于以下场景，检索维度始终落到结构化列）
--    - document_ocr.field_bbox_map：字段 -> bbox/页码/时间戳
--    - crf_field.options：类别枚举的展示候选项
--    - case_crf_value.value_json：数组 / 复杂结构兜底
--    - yaby_snapshot.payload：YABY 最小字段集快照内容
--    - upload_job.extraction_payload：AI 抽取原始结果
--    - audit_log.diff、field_change_log.before/after、export_log.deid_strategy
--
-- 6. 外键
--    业务主线表之间显式 FOREIGN KEY，默认 ON DELETE RESTRICT / ON UPDATE
--    CASCADE。审计 / 日志 / 投影表不加 FK，仅普通索引，避免锁竞争。
--    user 表自身 created_by/updated_by 不加 FK，避免循环依赖（应用层校验）。
--
-- 7. 字符集与时区
--    所有 CHAR/VARCHAR/TEXT 列使用 utf8mb4_0900_ai_ci。
--    所有 DATETIME 使用 (3) 毫秒精度，统一以 UTC 存储；展示层做时区转换。
--
-- 8. 与原型字段映射（重要）
--    Flutter 原型字段 -> 数据库表
--      CaseSummary / CaseDetail        -> `case` + L2 facts + crf_template
--      DiseaseProfile                  -> disease_profile
--      CRFTemplate / CRFSection / CRFField -> crf_template / crf_section / crf_field
--      CaseCRFValue                    -> case_crf_value
--      FieldMapping                    -> crf_field_mapping
--      EvidenceDocument / Anchor       -> document / evidence_anchor
--      TimelineEvent                   -> clinical_event + event_link
--      StructuredField                 -> case_crf_value（statusFilled）
--      CompletenessTask / ConflictEntry -> completeness_task / task_conflict_entry
--      ScreeningSnapshot               -> yaby_snapshot + case_screening_status
--      UploadJob / ExtractionDetail    -> upload_job / extraction_detail
--      InboxItem                       -> 视图聚合（无独立表，由 upload_job
--                                         + completeness_task 联合查询得到）
-- =============================================================================

SET NAMES utf8mb4;
SET TIME_ZONE = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- 模块 A：基础码表 / 字典
-- =============================================================================

DROP TABLE IF EXISTS `code_value_alias`;
DROP TABLE IF EXISTS `code_value`;
DROP TABLE IF EXISTS `code_set`;

CREATE TABLE `code_set` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(64)  NOT NULL                    COMMENT '码表唯一标识，例如 DocType / DrugClass',
  `name`          VARCHAR(128) NOT NULL                    COMMENT '码表中文名',
  `source`        VARCHAR(64)  NULL                        COMMENT '来源：ICD10 / SNOMED / ATC / 院内 等',
  `description`   VARCHAR(512) NULL                        COMMENT '说明',
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1          COMMENT '是否启用',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code_set_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='码表元信息';

CREATE TABLE `code_value` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code_set_id`   BIGINT UNSIGNED NOT NULL,
  `code`          VARCHAR(64)  NOT NULL                    COMMENT '码值，例如 PD1 / IO_MONO / OPD',
  `label`         VARCHAR(128) NOT NULL                    COMMENT '展示名',
  `parent_code`   VARCHAR(64)  NULL                        COMMENT '父级 code，用于层级码表',
  `sort_order`    INT          NOT NULL DEFAULT 0,
  `is_active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `extra`         JSON         NULL                        COMMENT '附加属性（颜色、单位、ICD 映射等）',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code_value` (`code_set_id`, `code`),
  KEY `idx_code_value_parent` (`code_set_id`, `parent_code`),
  CONSTRAINT `fk_code_value_set` FOREIGN KEY (`code_set_id`) REFERENCES `code_set` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='码表条目';

CREATE TABLE `code_value_alias` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code_set_id`   BIGINT UNSIGNED NOT NULL,
  `code_value_id` BIGINT UNSIGNED NOT NULL,
  `alias`         VARCHAR(128) NOT NULL                    COMMENT '别名 / 同义词，用于 OCR 归一化',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code_value_alias` (`code_set_id`, `alias`),
  KEY `idx_code_value_alias_target` (`code_value_id`),
  CONSTRAINT `fk_code_alias_set` FOREIGN KEY (`code_set_id`) REFERENCES `code_set` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_code_alias_value` FOREIGN KEY (`code_value_id`) REFERENCES `code_value` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='码表别名表（OCR 同义词归一化）';

-- =============================================================================
-- 模块 B：用户 / 角色 / 权限
-- =============================================================================

DROP TABLE IF EXISTS `case_acl`;
DROP TABLE IF EXISTS `role_permission`;
DROP TABLE IF EXISTS `user_role`;
DROP TABLE IF EXISTS `permission`;
DROP TABLE IF EXISTS `role`;
DROP TABLE IF EXISTS `user`;

CREATE TABLE `user` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_uid`        CHAR(32)     NOT NULL                  COMMENT 'UUIDv7 外部稳定标识',
  `username`        VARCHAR(64)  NOT NULL                  COMMENT '登录名',
  `display_name`    VARCHAR(64)  NOT NULL                  COMMENT '展示名/真实姓名',
  `phone`           VARCHAR(32)  NULL                      COMMENT '手机号（可空，建议加密存储）',
  `email`           VARCHAR(128) NULL,
  `password_hash`   VARCHAR(255) NULL                      COMMENT 'bcrypt/argon2 hash',
  `avatar_url`      VARCHAR(512) NULL,
  `title`           VARCHAR(64)  NULL                      COMMENT '职务，例如 主治医师 / 项目秘书',
  `dept`            VARCHAR(128) NULL                      COMMENT '科室',
  `status`          ENUM('active','disabled','locked') NOT NULL DEFAULT 'active',
  `last_login_at`   DATETIME(3)  NULL,
  `last_login_ip`   VARCHAR(45)  NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_uid` (`user_uid`),
  UNIQUE KEY `uk_user_username` (`username`, `deleted_marker`),
  UNIQUE KEY `uk_user_phone` (`phone`, `deleted_marker`),
  UNIQUE KEY `uk_user_email` (`email`, `deleted_marker`),
  KEY `idx_user_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户账号';

CREATE TABLE `role` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(64)  NOT NULL                    COMMENT '角色 code，例如 doctor / coordinator / admin / ai_service',
  `name`          VARCHAR(64)  NOT NULL,
  `description`   VARCHAR(255) NULL,
  `is_builtin`    TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '系统内置角色不可删除',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`    DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色';

CREATE TABLE `permission` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code`          VARCHAR(96)  NOT NULL                    COMMENT '权限点，例如 case.read / crf.template.publish',
  `name`          VARCHAR(96)  NOT NULL,
  `module`        VARCHAR(32)  NOT NULL                    COMMENT '所属模块：case / crf / screening / admin',
  `description`   VARCHAR(255) NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_permission_code` (`code`),
  KEY `idx_permission_module` (`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='权限点';

CREATE TABLE `user_role` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `role_id`       BIGINT UNSIGNED NOT NULL,
  `granted_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `granted_by`    BIGINT UNSIGNED NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_role` (`user_id`, `role_id`),
  KEY `idx_user_role_role` (`role_id`),
  CONSTRAINT `fk_user_role_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_role_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用户-角色 多对多';

CREATE TABLE `role_permission` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id`       BIGINT UNSIGNED NOT NULL,
  `permission_id` BIGINT UNSIGNED NOT NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_permission` (`role_id`, `permission_id`),
  KEY `idx_role_permission_perm` (`permission_id`),
  CONSTRAINT `fk_role_perm_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_role_perm_perm` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='角色-权限 多对多';

-- =============================================================================
-- 模块 C：患者 / 就诊
-- =============================================================================

DROP TABLE IF EXISTS `encounter`;
DROP TABLE IF EXISTS `patient_mrn`;
DROP TABLE IF EXISTS `patient`;

CREATE TABLE `patient` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_uid`     CHAR(32)     NOT NULL                  COMMENT 'UUIDv7 外部稳定标识',
  `name`            VARCHAR(64)  NOT NULL                  COMMENT '姓名（高敏；TODO：必要时改为加密列 + name_hash）',
  `name_pinyin`     VARCHAR(128) NULL                      COMMENT '拼音首字母，用于检索',
  `name_hash`       CHAR(64)     NULL                      COMMENT '姓名 SHA256，用于去重比对',
  `sex`             ENUM('M','F','U') NOT NULL DEFAULT 'U' COMMENT 'M=男 F=女 U=未知',
  `birth_year`      SMALLINT     NULL                      COMMENT '出生年',
  `birth_date`      DATE         NULL                      COMMENT '出生日期（高敏，可空）',
  `id_number_cipher` VARBINARY(255) NULL                   COMMENT '身份证号密文（应用层 AES）',
  `id_number_hash`  CHAR(64)     NULL                      COMMENT '身份证号哈希，用于去重',
  `mrn_primary`     VARCHAR(64)  NULL                      COMMENT '主就诊号 / 院内主索引号',
  `phone_cipher`    VARBINARY(128) NULL,
  `nation`          VARCHAR(32)  NULL,
  `marital_status`  VARCHAR(16)  NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_patient_uid` (`patient_uid`),
  UNIQUE KEY `uk_patient_mrn_primary` (`mrn_primary`, `deleted_marker`),
  UNIQUE KEY `uk_patient_id_number_hash` (`id_number_hash`, `deleted_marker`),
  KEY `idx_patient_birth_sex` (`birth_year`, `sex`),
  KEY `idx_patient_name_pinyin` (`name_pinyin`),
  KEY `idx_patient_name_hash` (`name_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='患者主索引（PHI 高敏）';

CREATE TABLE `patient_mrn` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id`      BIGINT UNSIGNED NOT NULL,
  `source_org_code` VARCHAR(64)  NOT NULL DEFAULT 'self'   COMMENT '来源机构 code，self=本院，便于后期接外院',
  `mrn`             VARCHAR(64)  NOT NULL                  COMMENT '住院号 / 门诊号',
  `mrn_type`        VARCHAR(32)  NOT NULL                  COMMENT 'inpatient / outpatient / hic / external',
  `is_primary`      TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_patient_mrn` (`source_org_code`, `mrn`, `deleted_marker`),
  KEY `idx_patient_mrn_patient` (`patient_id`),
  CONSTRAINT `fk_patient_mrn_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='患者就诊号（一患多号）';

CREATE TABLE `encounter` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `encounter_uid`   CHAR(32)     NOT NULL,
  `patient_id`      BIGINT UNSIGNED NOT NULL,
  `encounter_type`  ENUM('OPD','IPD','ER','FU','DAY') NOT NULL COMMENT '门诊/住院/急诊/随访/日间',
  `dept`            VARCHAR(128) NULL,
  `attending_doctor` VARCHAR(64) NULL,
  `admit_date`      DATE         NULL                      COMMENT '入院/就诊日期',
  `discharge_date`  DATE         NULL                      COMMENT '出院日期',
  `source_org_code` VARCHAR(64)  NOT NULL DEFAULT 'self',
  `mrn`             VARCHAR(64)  NULL                      COMMENT '本次就诊号',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_encounter_uid` (`encounter_uid`),
  KEY `idx_encounter_patient_admit` (`patient_id`, `admit_date`),
  KEY `idx_encounter_type_admit` (`encounter_type`, `admit_date`),
  CONSTRAINT `fk_encounter_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='就诊记录';

-- =============================================================================
-- 模块 D：CRF 配置（瘤种 / 模板 / 字段 / 映射）
-- =============================================================================

DROP TABLE IF EXISTS `crf_field_mapping`;
DROP TABLE IF EXISTS `crf_field`;
DROP TABLE IF EXISTS `crf_section`;
DROP TABLE IF EXISTS `crf_template`;
DROP TABLE IF EXISTS `disease_profile`;

CREATE TABLE `disease_profile` (
  `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `profile_uid`        CHAR(32)     NOT NULL,
  `group_code`         VARCHAR(32)  NOT NULL                  COMMENT '瘤种组 code：GU / LUNG / BREAST / GI / GYN / RARE',
  `group_name`         VARCHAR(64)  NOT NULL,
  `tumor_code`         VARCHAR(32)  NOT NULL                  COMMENT '具体瘤种 code：bladder / prostate / nsclc 等',
  `tumor_name`         VARCHAR(64)  NOT NULL,
  `default_template_id` BIGINT UNSIGNED NULL                  COMMENT '默认 active 模板，FK 在模板创建后回填（无强 FK，避免循环）',
  `display_color`      VARCHAR(16)  NULL,
  `enabled`            TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at`         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`         BIGINT UNSIGNED NULL,
  `updated_by`         BIGINT UNSIGNED NULL,
  `deleted_at`         DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`     BIGINT UNSIGNED NOT NULL
                       DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_disease_profile_uid` (`profile_uid`),
  UNIQUE KEY `uk_disease_profile_code` (`group_code`, `tumor_code`, `deleted_marker`),
  KEY `idx_disease_profile_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='瘤种 / 瘤种组';

CREATE TABLE `crf_template` (
  `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_uid`       CHAR(32)     NOT NULL,
  `disease_profile_id` BIGINT UNSIGNED NOT NULL,
  `version`            VARCHAR(32)  NOT NULL                  COMMENT '版本号，例如 V2026-03',
  `title`              VARCHAR(128) NOT NULL,
  `status`             ENUM('draft','active','archived') NOT NULL DEFAULT 'draft',
  `change_log`         TEXT         NULL                      COMMENT '版本变更说明',
  `field_count`        INT          NOT NULL DEFAULT 0        COMMENT '字段总数（冗余，便于列表展示）',
  `blocking_count`     INT          NOT NULL DEFAULT 0,
  `governance_count`   INT          NOT NULL DEFAULT 0,
  `published_at`       DATETIME(3)  NULL,
  `created_at`         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`         BIGINT UNSIGNED NULL,
  `updated_by`         BIGINT UNSIGNED NULL,
  `deleted_at`         DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`     BIGINT UNSIGNED NOT NULL
                       DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  `active_marker`      TINYINT UNSIGNED
                       GENERATED ALWAYS AS (IF(`status`='active', 1, NULL)) STORED NULL
                       COMMENT '辅助列：仅当 status=active 时为 1，配合唯一索引保证同一 profile 仅一条 active',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crf_template_uid` (`template_uid`),
  UNIQUE KEY `uk_crf_template_version` (`disease_profile_id`, `version`, `deleted_marker`),
  UNIQUE KEY `uk_crf_template_active` (`disease_profile_id`, `active_marker`),
  KEY `idx_crf_template_status` (`status`),
  CONSTRAINT `fk_crf_template_profile` FOREIGN KEY (`disease_profile_id`) REFERENCES `disease_profile` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='CRF 模板（按瘤种 + 版本）';

CREATE TABLE `crf_section` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`   BIGINT UNSIGNED NOT NULL,
  `parent_id`     BIGINT UNSIGNED NULL                      COMMENT '上级 section，根节点为 NULL',
  `code`          VARCHAR(96)  NOT NULL                    COMMENT '模块 code，例如 gu.basic_info',
  `title`         VARCHAR(128) NOT NULL,
  `level`         TINYINT      NOT NULL DEFAULT 1          COMMENT '1/2/3 级模块',
  `sort_order`    INT          NOT NULL DEFAULT 0,
  `description`   VARCHAR(512) NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`    DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crf_section_code` (`template_id`, `code`),
  KEY `idx_crf_section_parent` (`parent_id`),
  KEY `idx_crf_section_template` (`template_id`, `level`, `sort_order`),
  CONSTRAINT `fk_crf_section_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_section_parent` FOREIGN KEY (`parent_id`) REFERENCES `crf_section` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='CRF 模板章节（树形）';

CREATE TABLE `crf_field` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`       BIGINT UNSIGNED NOT NULL,
  `section_id`        BIGINT UNSIGNED NOT NULL,
  `field_code`        VARCHAR(128) NOT NULL                  COMMENT '稳定字段编码，例如 gu.pathology.pt',
  `path`              VARCHAR(512) NOT NULL                  COMMENT '冗余完整路径，例如 辅助检查/病理检查/pT',
  `label`             VARCHAR(128) NOT NULL,
  `data_type`         ENUM('text','number','date','datetime','category','boolean','unknown') NOT NULL DEFAULT 'unknown',
  `required_level`    ENUM('blocking','recommended','optional') NOT NULL DEFAULT 'optional',
  `unit`              VARCHAR(32)  NULL,
  `format`            VARCHAR(64)  NULL                      COMMENT '日期/数值格式说明',
  `source`            VARCHAR(128) NULL                      COMMENT '建议来源文档类型',
  `description`       VARCHAR(1024) NULL,
  `options`           JSON         NULL                      COMMENT 'category 类型的候选项',
  `value_code_set`    VARCHAR(64)  NULL                      COMMENT 'category 类型若挂码表，存 code_set.code',
  `repeatable`        TINYINT(1)   NOT NULL DEFAULT 0        COMMENT '是否允许重复多值',
  `searchable`        TINYINT(1)   NOT NULL DEFAULT 0        COMMENT '是否进入专病搜索面板',
  `governance_status` ENUM('governed','need_governance','pending') NOT NULL DEFAULT 'governed',
  `sort_order`        INT          NOT NULL DEFAULT 0,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`    BIGINT UNSIGNED NOT NULL
                      DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crf_field_code` (`template_id`, `field_code`, `deleted_marker`),
  KEY `idx_crf_field_section` (`section_id`, `sort_order`),
  KEY `idx_crf_field_searchable` (`template_id`, `searchable`),
  KEY `idx_crf_field_required` (`template_id`, `required_level`),
  KEY `idx_crf_field_governance` (`template_id`, `governance_status`),
  CONSTRAINT `fk_crf_field_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_field_section` FOREIGN KEY (`section_id`) REFERENCES `crf_section` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='CRF 字段定义';

CREATE TABLE `crf_field_mapping` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `template_id`       BIGINT UNSIGNED NOT NULL,
  `crf_field_id`      BIGINT UNSIGNED NOT NULL,
  `crf_field_code`    VARCHAR(128) NOT NULL                  COMMENT '冗余 field_code，便于跨版本迁移',
  `canonical_entity`  VARCHAR(64)  NOT NULL                  COMMENT '主干实体名，例如 VitalSigns / Stage / Biomarker / LabResult',
  `canonical_field`   VARCHAR(64)  NOT NULL                  COMMENT '主干字段名，例如 ecog / tnm_t',
  `mapping_type`      ENUM('direct','normalize','derive','aggregate') NOT NULL DEFAULT 'direct',
  `transform_rule`    TEXT         NULL                      COMMENT 'DSL/JSONata/SQL 等规则描述',
  `is_writeback`      TINYINT(1)   NOT NULL DEFAULT 1        COMMENT '是否回写主干',
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crf_mapping` (`crf_field_id`, `canonical_entity`, `canonical_field`),
  KEY `idx_crf_mapping_template` (`template_id`),
  KEY `idx_crf_mapping_canonical` (`canonical_entity`, `canonical_field`),
  CONSTRAINT `fk_crf_mapping_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_mapping_field` FOREIGN KEY (`crf_field_id`) REFERENCES `crf_field` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='CRF 字段 -> 通用主干字段映射';

-- =============================================================================
-- 模块 E：病例（聚合根）
-- =============================================================================

DROP TABLE IF EXISTS `case_acl`;
DROP TABLE IF EXISTS `case_template_history`;
DROP TABLE IF EXISTS `case`;

CREATE TABLE `case` (
  `id`                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_uid`                 CHAR(32)     NOT NULL,
  `patient_id`               BIGINT UNSIGNED NOT NULL,
  `disease_profile_id`       BIGINT UNSIGNED NOT NULL,
  `crf_template_id`          BIGINT UNSIGNED NOT NULL                  COMMENT '当前绑定模板，会随版本升级变更（旧版历史进 case_template_history）',
  `crf_template_version`     VARCHAR(32)  NOT NULL,
  `patient_code_label`       VARCHAR(64)  NULL                          COMMENT '展示给医生的脱敏编号（与 patient.mrn_primary 区分）',
  -- 通用主干快照字段（冗余，便于列表/卡片展示，避免 join 全部 L2）
  `primary_site`             VARCHAR(128) NULL,
  `primary_site_code`        VARCHAR(32)  NULL                          COMMENT 'SNOMED/ICD-O 编码',
  `tumor_type`               VARCHAR(64)  NULL,
  `histology`                VARCHAR(128) NULL,
  `stage_label`              VARCHAR(32)  NULL                          COMMENT '例如 IIIB / IVB',
  `line_of_therapy`          TINYINT      NULL,
  `current_regimen_label`    VARCHAR(128) NULL,
  `current_regimen_type`     VARCHAR(32)  NULL                          COMMENT 'code: IO_MONO / CHEMO_IO / TKI_IO / CHEMO_ONLY',
  `metastatic_sites`         VARCHAR(255) NULL,
  `disease_status`           VARCHAR(32)  NULL,
  `ecog`                     TINYINT      NULL,
  `has_liver_risk`           TINYINT(1)   NOT NULL DEFAULT 0,
  `screening_status`         ENUM('not_ready','partial','ready') NOT NULL DEFAULT 'not_ready',
  `core_completion_rate`     DECIMAL(5,4) NOT NULL DEFAULT 0.0000       COMMENT '通用主干完整度',
  `crf_completion_rate`      DECIMAL(5,4) NOT NULL DEFAULT 0.0000       COMMENT '专病 CRF 完整度',
  `crf_blocking_missing_count` INT        NOT NULL DEFAULT 0,
  `crf_conflict_count`       INT          NOT NULL DEFAULT 0,
  `diagnosis_date`           DATE         NULL,
  `last_event_at`            DATETIME(3)  NULL                          COMMENT '最后一次时间线事件时间',
  `last_updated_at`          DATETIME(3)  NULL                          COMMENT '最后一次任意字段被更新时间',
  `owner_user_id`            BIGINT UNSIGNED NULL                       COMMENT '主负责人',
  `created_at`               DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`               DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`               BIGINT UNSIGNED NULL,
  `updated_by`               BIGINT UNSIGNED NULL,
  `deleted_at`               DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`           BIGINT UNSIGNED NOT NULL
                             DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_uid` (`case_uid`),
  UNIQUE KEY `uk_case_patient_profile` (`patient_id`, `disease_profile_id`, `deleted_marker`),
  KEY `idx_case_profile_status` (`disease_profile_id`, `screening_status`),
  KEY `idx_case_template_completion` (`crf_template_id`, `crf_completion_rate`),
  KEY `idx_case_owner` (`owner_user_id`),
  KEY `idx_case_last_updated` (`last_updated_at`),
  CONSTRAINT `fk_case_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_case_profile` FOREIGN KEY (`disease_profile_id`) REFERENCES `disease_profile` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_case_template` FOREIGN KEY (`crf_template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例（聚合根）';

CREATE TABLE `case_template_history` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `from_template_id`  BIGINT UNSIGNED NULL,
  `to_template_id`    BIGINT UNSIGNED NOT NULL,
  `from_version`      VARCHAR(32)  NULL,
  `to_version`        VARCHAR(32)  NOT NULL,
  `migration_note`    TEXT         NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_by`        BIGINT UNSIGNED NULL,
  PRIMARY KEY (`id`),
  KEY `idx_case_tpl_history_case` (`case_id`, `created_at`),
  CONSTRAINT `fk_case_tpl_history_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例模板版本变更历史';

CREATE TABLE `case_acl` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`       BIGINT UNSIGNED NOT NULL,
  `subject_type`  ENUM('user','role') NOT NULL,
  `subject_id`    BIGINT UNSIGNED NOT NULL,
  `permission`    ENUM('read','write','admin') NOT NULL DEFAULT 'read',
  `granted_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `granted_by`    BIGINT UNSIGNED NULL,
  `expires_at`    DATETIME(3)  NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_acl` (`case_id`, `subject_type`, `subject_id`, `permission`),
  KEY `idx_case_acl_subject` (`subject_type`, `subject_id`),
  CONSTRAINT `fk_case_acl_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例级权限（覆盖默认 RBAC）';

-- =============================================================================
-- 模块 F：文档与证据（L0 / L1）
-- =============================================================================

DROP TABLE IF EXISTS `evidence_anchor`;
DROP TABLE IF EXISTS `document_ocr`;
DROP TABLE IF EXISTS `document_page`;
DROP TABLE IF EXISTS `document`;

CREATE TABLE `document` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `document_uid`    CHAR(32)     NOT NULL,
  `patient_id`      BIGINT UNSIGNED NOT NULL,
  `case_id`         BIGINT UNSIGNED NULL,
  `encounter_id`    BIGINT UNSIGNED NULL,
  `event_id`        BIGINT UNSIGNED NULL                      COMMENT 'L3 事件 id，可解析后回填',
  `modality`        ENUM('IMG','PDF','AUDIO','VIDEO','TEXT') NOT NULL,
  `doc_type_code`   VARCHAR(64)  NULL                         COMMENT '字典：检验单/影像报告/病理报告/出院小结...',
  `title`           VARCHAR(255) NULL,
  `file_uri`        VARCHAR(1024) NOT NULL                    COMMENT '对象存储路径或本地路径',
  `file_hash`       CHAR(64)     NOT NULL                     COMMENT 'SHA256，用于去重',
  `file_size`       BIGINT       NULL,
  `mime_type`       VARCHAR(96)  NULL,
  `storage_provider` VARCHAR(32) NOT NULL DEFAULT 'oss'       COMMENT 'oss / s3 / local / cos',
  `page_count`      INT          NULL,
  `duration_ms`     INT          NULL                         COMMENT '语音/视频时长',
  `source_org_code` VARCHAR(64)  NULL,
  `exif_datetime`   DATETIME(3)  NULL,
  `report_date`     DATE         NULL,
  `sample_date`     DATE         NULL,
  `processing_status` ENUM('uploaded','ocr_pending','ocr_done','extract_pending','extracted','reviewed','failed')
                    NOT NULL DEFAULT 'uploaded',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_document_uid` (`document_uid`),
  UNIQUE KEY `uk_document_hash` (`file_hash`, `deleted_marker`),
  KEY `idx_document_patient` (`patient_id`, `report_date`),
  KEY `idx_document_case` (`case_id`),
  KEY `idx_document_encounter` (`encounter_id`),
  KEY `idx_document_event` (`event_id`),
  KEY `idx_document_modality` (`modality`, `processing_status`),
  KEY `idx_document_doctype` (`doc_type_code`),
  CONSTRAINT `fk_document_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_document_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_document_encounter` FOREIGN KEY (`encounter_id`) REFERENCES `encounter` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='原始资料 / 多模态文档（L0）';

CREATE TABLE `document_page` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `document_id`   BIGINT UNSIGNED NOT NULL,
  `page_no`       INT          NOT NULL,
  `image_uri`     VARCHAR(1024) NULL                       COMMENT '页面渲染图片，便于前端预览',
  `page_hash`     CHAR(64)     NULL,
  `width_px`      INT          NULL,
  `height_px`     INT          NULL,
  `ocr_text`      MEDIUMTEXT   NULL                        COMMENT '页面级 OCR',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_document_page` (`document_id`, `page_no`),
  CONSTRAINT `fk_document_page_doc` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文档分页';

CREATE TABLE `document_ocr` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `document_id`       BIGINT UNSIGNED NOT NULL,
  `engine`            VARCHAR(64)  NULL                      COMMENT 'OCR/ASR 引擎与版本',
  `language`          VARCHAR(16)  NOT NULL DEFAULT 'zh-CN',
  `full_text`         MEDIUMTEXT   NOT NULL,
  `field_bbox_map`    JSON         NULL                      COMMENT '字段定位映射：fieldCode -> [{page, bbox, time_offset}]',
  `confidence_score`  DECIMAL(5,4) NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_document_ocr_doc` (`document_id`),
  FULLTEXT KEY `ft_document_ocr_text` (`full_text`) WITH PARSER ngram,
  CONSTRAINT `fk_document_ocr_doc` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文档全文 OCR/ASR 产物';

CREATE TABLE `evidence_anchor` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `document_id`   BIGINT UNSIGNED NOT NULL,
  `anchor_type`   ENUM('bbox','time_range','text_offset') NOT NULL,
  `page_no`       INT          NULL,
  `bbox`          JSON         NULL                        COMMENT '[x,y,w,h] 归一化坐标',
  `time_start_ms` INT          NULL                        COMMENT '语音时间戳（毫秒）',
  `time_end_ms`   INT          NULL,
  `text_offset`   INT          NULL,
  `text_length`   INT          NULL,
  `excerpt`       VARCHAR(1024) NULL                       COMMENT '原文片段',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_evidence_doc` (`document_id`, `page_no`),
  CONSTRAINT `fk_evidence_anchor_doc` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='证据锚点（字段定位）';

-- =============================================================================
-- 模块 G：时间线（L3）
-- =============================================================================

DROP TABLE IF EXISTS `event_link`;
DROP TABLE IF EXISTS `clinical_event`;

CREATE TABLE `clinical_event` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_uid`       CHAR(32)     NOT NULL,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_type_code` VARCHAR(64)  NOT NULL                    COMMENT '字典 EventType：诊断/分期/手术/影像/检验/AE/随访...',
  `title`           VARCHAR(255) NOT NULL,
  `subtitle`        VARCHAR(255) NULL,
  `description`     TEXT         NULL,
  `event_date`      DATE         NOT NULL,
  `event_time`      TIME         NULL,
  `date_source`     ENUM('entry','collect','report','infer') NOT NULL DEFAULT 'entry',
  `is_important`    TINYINT(1)   NOT NULL DEFAULT 0,
  `encounter_id`    BIGINT UNSIGNED NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_event_uid` (`event_uid`),
  KEY `idx_event_case_date` (`case_id`, `event_date`),
  KEY `idx_event_type` (`event_type_code`, `event_date`),
  CONSTRAINT `fk_event_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_event_encounter` FOREIGN KEY (`encounter_id`) REFERENCES `encounter` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='临床事件（时间线节点）';

CREATE TABLE `event_link` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_id`      BIGINT UNSIGNED NOT NULL,
  `target_table`  VARCHAR(64)  NOT NULL                    COMMENT '关联的 L2 实体表名，如 lab_result / biomarker_result / drug_exposure',
  `target_id`     BIGINT UNSIGNED NOT NULL,
  `link_type`     VARCHAR(32)  NOT NULL DEFAULT 'fact'     COMMENT 'fact / evidence / derived',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_event_link` (`event_id`, `target_table`, `target_id`),
  KEY `idx_event_link_target` (`target_table`, `target_id`),
  CONSTRAINT `fk_event_link_event` FOREIGN KEY (`event_id`) REFERENCES `clinical_event` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='事件 -> L2 事实多对多';

-- =============================================================================
-- 模块 H：L2 临床事实表
-- =============================================================================

DROP TABLE IF EXISTS `infection_status`;
DROP TABLE IF EXISTS `comorbidity`;
DROP TABLE IF EXISTS `vital_signs`;
DROP TABLE IF EXISTS `radiotherapy_detail`;
DROP TABLE IF EXISTS `procedure`;
DROP TABLE IF EXISTS `adverse_event`;
DROP TABLE IF EXISTS `imaging_report`;
DROP TABLE IF EXISTS `imaging_study`;
DROP TABLE IF EXISTS `pathology_report`;
DROP TABLE IF EXISTS `lab_result`;
DROP TABLE IF EXISTS `lab_panel`;
DROP TABLE IF EXISTS `dose_change`;
DROP TABLE IF EXISTS `drug_exposure`;
DROP TABLE IF EXISTS `regimen`;
DROP TABLE IF EXISTS `line_of_therapy`;
DROP TABLE IF EXISTS `biomarker_result`;
DROP TABLE IF EXISTS `molecular_result`;
DROP TABLE IF EXISTS `molecular_test`;
DROP TABLE IF EXISTS `stage`;
DROP TABLE IF EXISTS `diagnosis`;

CREATE TABLE `diagnosis` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`             BIGINT UNSIGNED NOT NULL,
  `event_id`            BIGINT UNSIGNED NULL,
  `evidence_id`         BIGINT UNSIGNED NULL,
  `diagnosis_date`      DATE         NULL,
  `primary_site_code`   VARCHAR(64)  NULL                    COMMENT 'SNOMED / ICD-O Topography',
  `primary_site_label`  VARCHAR(128) NULL,
  `icd10_code`          VARCHAR(32)  NULL,
  `histology`           VARCHAR(128) NULL,
  `pathology_diagnosis` VARCHAR(255) NULL,
  `is_primary`          TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '是否原发灶诊断',
  `confidence`          ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`          DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`          DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`          BIGINT UNSIGNED NULL,
  `updated_by`          BIGINT UNSIGNED NULL,
  `deleted_at`          DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_diagnosis_case` (`case_id`, `is_primary`),
  KEY `idx_diagnosis_event` (`event_id`),
  KEY `idx_diagnosis_icd10` (`icd10_code`),
  KEY `idx_diagnosis_site` (`primary_site_code`),
  CONSTRAINT `fk_diagnosis_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_diagnosis_event` FOREIGN KEY (`event_id`) REFERENCES `clinical_event` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='诊断';

CREATE TABLE `stage` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `stage_kind`      ENUM('clinical','pathologic') NOT NULL DEFAULT 'clinical',
  `stage_system`    VARCHAR(32)  NULL                        COMMENT 'AJCC8 / AJCC9 / 院内',
  `tnm_t`           VARCHAR(16)  NULL,
  `tnm_n`           VARCHAR(16)  NULL,
  `tnm_m`           VARCHAR(16)  NULL,
  `ajcc_stage`      VARCHAR(16)  NULL,
  `staged_at`       DATE         NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_stage_case_kind` (`case_id`, `stage_kind`, `staged_at`),
  KEY `idx_stage_event` (`event_id`),
  CONSTRAINT `fk_stage_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_stage_event` FOREIGN KEY (`event_id`) REFERENCES `clinical_event` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='分期（含 cTNM/pTNM）';

CREATE TABLE `molecular_test` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `test_name`       VARCHAR(128) NULL,
  `sample_type`     ENUM('TISSUE','BLOOD','ctDNA','URINE','OTHER','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
  `platform`        VARCHAR(64)  NULL,
  `lab_org`         VARCHAR(128) NULL,
  `report_date`     DATE         NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_molecular_test_case` (`case_id`, `report_date`),
  CONSTRAINT `fk_mol_test_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='分子检测批次';

CREATE TABLE `molecular_result` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `test_id`         BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `gene`            VARCHAR(32)  NOT NULL                    COMMENT 'HGNC 基因名',
  `variant`         VARCHAR(128) NULL                        COMMENT '19del / L858R / FUSION 等',
  `status`          ENUM('POS','NEG','NOT_TESTED','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN'
                    COMMENT '关键：必须区分 NEG 与 NOT_TESTED',
  `vaf`             DECIMAL(7,4) NULL                        COMMENT '变异频率',
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_mol_result_case_gene` (`case_id`, `gene`, `status`),
  KEY `idx_mol_result_test` (`test_id`),
  CONSTRAINT `fk_mol_result_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_mol_result_test` FOREIGN KEY (`test_id`) REFERENCES `molecular_test` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='基因 / 变异检测结果';

CREATE TABLE `biomarker_result` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `biomarker_code`  VARCHAR(32)  NOT NULL                    COMMENT 'PD-L1 / MSI / TMB / HER2 / Ki67',
  `biomarker_name`  VARCHAR(64)  NOT NULL,
  `value_text`      VARCHAR(64)  NULL                        COMMENT 'CPS=20 / TPS=高表达 / dMMR / 3+',
  `value_number`    DECIMAL(10,4) NULL,
  `unit`            VARCHAR(32)  NULL,
  `result_date`     DATE         NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_biomarker_case_code` (`case_id`, `biomarker_code`, `result_date`),
  KEY `idx_biomarker_code` (`biomarker_code`),
  CONSTRAINT `fk_biomarker_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='生物标志物结果';

CREATE TABLE `line_of_therapy` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `line_no`         TINYINT      NOT NULL                    COMMENT '1L / 2L / ...',
  `start_date`      DATE         NULL,
  `end_date`        DATE         NULL,
  `intent`          VARCHAR(32)  NULL                        COMMENT '新辅助 / 辅助 / 姑息 / 维持',
  `stop_reason`     VARCHAR(32)  NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_line_case_no` (`case_id`, `line_no`, `deleted_marker`),
  CONSTRAINT `fk_lot_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='治疗线数';

CREATE TABLE `regimen` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `line_id`           BIGINT UNSIGNED NULL,
  `event_id`          BIGINT UNSIGNED NULL,
  `regimen_name_std`  VARCHAR(128) NULL                      COMMENT '院内字典 + ATC',
  `regimen_name_raw`  VARCHAR(255) NULL,
  `regimen_type`      VARCHAR(32)  NULL                      COMMENT '字典 RegimenType: IO_MONO / CHEMO_IO / TKI_IO / CHEMO_ONLY ...',
  `start_date`        DATE         NULL,
  `end_date`          DATE         NULL,
  `cycle_count`       INT          NULL,
  `confidence`        ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_regimen_case_line` (`case_id`, `line_id`),
  KEY `idx_regimen_type` (`regimen_type`),
  CONSTRAINT `fk_regimen_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_regimen_line` FOREIGN KEY (`line_id`) REFERENCES `line_of_therapy` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='治疗方案';

CREATE TABLE `drug_exposure` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `regimen_id`      BIGINT UNSIGNED NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `drug_generic`    VARCHAR(128) NOT NULL                    COMMENT '通用名（ATC 推荐）',
  `drug_brand`      VARCHAR(128) NULL,
  `drug_class`      VARCHAR(32)  NOT NULL                    COMMENT '字典 DrugClass: PD1 / PDL1 / TKI / CHEMO_PLATINUM ...',
  `dose_value`      DECIMAL(10,4) NULL,
  `dose_unit`       VARCHAR(32)  NULL,
  `route`           VARCHAR(32)  NULL                        COMMENT 'IV / PO / IH ...',
  `frequency`       VARCHAR(32)  NULL,
  `start_date`      DATE         NULL,
  `end_date`        DATE         NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_drug_case_class` (`case_id`, `drug_class`, `start_date`),
  KEY `idx_drug_regimen` (`regimen_id`),
  KEY `idx_drug_generic` (`drug_generic`),
  CONSTRAINT `fk_drug_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_drug_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='用药暴露';

CREATE TABLE `dose_change` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `drug_exposure_id`  BIGINT UNSIGNED NOT NULL,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `change_type`       ENUM('REDUCE','DELAY','STOP','RESUME','ESCALATE') NOT NULL,
  `change_date`       DATE         NULL,
  `reason_code`       VARCHAR(32)  NULL                      COMMENT '字典 ChangeReason',
  `reason_text`       VARCHAR(255) NULL,
  `new_dose_value`    DECIMAL(10,4) NULL,
  `new_dose_unit`     VARCHAR(32)  NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_dose_change_drug` (`drug_exposure_id`, `change_date`),
  KEY `idx_dose_change_case` (`case_id`),
  CONSTRAINT `fk_dose_change_drug` FOREIGN KEY (`drug_exposure_id`) REFERENCES `drug_exposure` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dose_change_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='剂量调整 / 停药';

CREATE TABLE `lab_panel` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `panel_name`      VARCHAR(128) NULL                        COMMENT '肝功 / 肾功 / 血常规',
  `collection_date` DATE         NOT NULL,
  `report_date`     DATE         NULL,
  `lab_org`         VARCHAR(128) NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lab_panel_case_date` (`case_id`, `collection_date`),
  CONSTRAINT `fk_lab_panel_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='检验批次（一次采血）';

CREATE TABLE `lab_result` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `panel_id`        BIGINT UNSIGNED NOT NULL,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `test_name_std`   VARCHAR(64)  NOT NULL                    COMMENT '标准名：ALT / AST / TBil / Cr / ANC ...',
  `test_name_raw`   VARCHAR(128) NULL,
  `loinc_code`      VARCHAR(32)  NULL,
  `value`           DECIMAL(20,6) NULL,
  `value_text`      VARCHAR(64)  NULL                        COMMENT '阴性/阳性/未测出 等',
  `unit`            VARCHAR(32)  NULL,
  `ref_low`         DECIMAL(20,6) NULL,
  `ref_high`        DECIMAL(20,6) NULL,
  `is_abnormal`     TINYINT(1)   NOT NULL DEFAULT 0,
  `ctcae_grade`     TINYINT      NULL                        COMMENT '0-5，CTCAE v5.0 派生',
  `collection_date` DATE         NOT NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lab_case_test_date` (`case_id`, `test_name_std`, `collection_date`),
  KEY `idx_lab_panel` (`panel_id`),
  KEY `idx_lab_abnormal` (`case_id`, `is_abnormal`, `test_name_std`),
  KEY `idx_lab_ctcae` (`case_id`, `test_name_std`, `ctcae_grade`),
  CONSTRAINT `fk_lab_result_panel` FOREIGN KEY (`panel_id`) REFERENCES `lab_panel` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_result_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='检验项结果';

CREATE TABLE `pathology_report` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `report_no`       VARCHAR(64)  NULL,
  `sample_type`     VARCHAR(64)  NULL                        COMMENT '穿刺 / 手术 / 活检',
  `gross_desc`      TEXT         NULL,
  `microscopic_desc` TEXT        NULL,
  `path_dx`         TEXT         NULL,
  `histology`       VARCHAR(128) NULL,
  `differentiation` VARCHAR(64)  NULL,
  `lvi`             TINYINT(1)   NULL                        COMMENT '脉管侵犯',
  `pni`             TINYINT(1)   NULL                        COMMENT '神经侵犯',
  `margin_status`   VARCHAR(32)  NULL,
  `lymph_total`     INT          NULL,
  `lymph_positive`  INT          NULL,
  `report_date`     DATE         NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pathology_case_date` (`case_id`, `report_date`),
  FULLTEXT KEY `ft_pathology_dx` (`path_dx`) WITH PARSER ngram,
  CONSTRAINT `fk_pathology_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病理报告';

CREATE TABLE `imaging_study` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `study_type`      VARCHAR(32)  NOT NULL                    COMMENT 'CT / MRI / PET-CT / 超声 / 骨扫描',
  `study_part`      VARCHAR(64)  NULL                        COMMENT '胸部 / 腹盆 / 全身',
  `study_date`      DATE         NOT NULL,
  `lab_org`         VARCHAR(128) NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_imaging_study_case_date` (`case_id`, `study_date`),
  KEY `idx_imaging_study_type` (`study_type`),
  CONSTRAINT `fk_imaging_study_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='影像检查';

CREATE TABLE `imaging_report` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `study_id`        BIGINT UNSIGNED NOT NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `findings`        TEXT         NULL,
  `impression`      TEXT         NULL,
  `response`        ENUM('CR','PR','SD','PD','UNKNOWN') NULL COMMENT 'RECIST 1.1',
  `report_date`     DATE         NULL,
  `radiologist`     VARCHAR(64)  NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_imaging_report_case` (`case_id`, `report_date`),
  KEY `idx_imaging_report_study` (`study_id`),
  KEY `idx_imaging_report_response` (`case_id`, `response`),
  FULLTEXT KEY `ft_imaging_impression` (`impression`) WITH PARSER ngram,
  CONSTRAINT `fk_imaging_report_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_imaging_report_study` FOREIGN KEY (`study_id`) REFERENCES `imaging_study` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='影像报告 / RECIST 评效';

CREATE TABLE `adverse_event` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `ae_term`         VARCHAR(128) NOT NULL                    COMMENT 'CTCAE 术语',
  `meddra_code`     VARCHAR(32)  NULL,
  `grade`           TINYINT      NOT NULL                    COMMENT '0-5',
  `start_date`      DATE         NULL,
  `end_date`        DATE         NULL,
  `attribution`     ENUM('RELATED','POSSIBLE','UNRELATED','UNKNOWN') NOT NULL DEFAULT 'UNKNOWN',
  `outcome`         VARCHAR(32)  NULL                        COMMENT '恢复 / 持续 / 死亡 / 后遗症',
  `is_serious`      TINYINT(1)   NOT NULL DEFAULT 0          COMMENT 'SAE 标记',
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ae_case_term` (`case_id`, `ae_term`, `start_date`),
  KEY `idx_ae_grade` (`case_id`, `grade`),
  CONSTRAINT `fk_ae_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='不良事件';

CREATE TABLE `procedure` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `proc_type`       ENUM('SURGERY','RT','INTERVENTION','BIOPSY','OTHER') NOT NULL,
  `proc_name`       VARCHAR(255) NULL,
  `icd9_code`       VARCHAR(32)  NULL,
  `proc_date`       DATE         NULL,
  `surgeon`         VARCHAR(64)  NULL,
  `description`     TEXT         NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_procedure_case` (`case_id`, `proc_date`),
  KEY `idx_procedure_type` (`proc_type`),
  CONSTRAINT `fk_procedure_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='手术 / 介入等处置';

CREATE TABLE `radiotherapy_detail` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `procedure_id`    BIGINT UNSIGNED NOT NULL,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `total_dose_gy`   DECIMAL(8,2) NULL,
  `fractions`       INT          NULL,
  `dose_per_fx_gy`  DECIMAL(8,2) NULL,
  `target_volume`   VARCHAR(128) NULL,
  `technique`       VARCHAR(64)  NULL                        COMMENT 'IMRT / VMAT / SBRT',
  `start_date`      DATE         NULL,
  `end_date`        DATE         NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_radiotherapy_proc` (`procedure_id`),
  KEY `idx_radiotherapy_case` (`case_id`),
  CONSTRAINT `fk_rt_procedure` FOREIGN KEY (`procedure_id`) REFERENCES `procedure` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rt_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='放疗细节（procedure 1:1 扩展）';

CREATE TABLE `vital_signs` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `record_date`     DATE         NULL,
  `ecog`            TINYINT      NULL                        COMMENT '0-5',
  `kps`             TINYINT      NULL                        COMMENT '0-100',
  `weight_kg`       DECIMAL(6,2) NULL,
  `height_cm`       DECIMAL(5,1) NULL,
  `bsa`             DECIMAL(5,2) NULL,
  `bmi`             DECIMAL(5,2) NULL,
  `bp_systolic`     INT          NULL,
  `bp_diastolic`    INT          NULL,
  `pulse`           INT          NULL,
  `temperature_c`   DECIMAL(4,1) NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_vital_case_date` (`case_id`, `record_date`),
  CONSTRAINT `fk_vital_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='生命体征 / ECOG';

CREATE TABLE `comorbidity` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `comorbidity_code` VARCHAR(32) NULL                        COMMENT '字典 Comorbidity / ICD10',
  `comorbidity_name` VARCHAR(128) NOT NULL,
  `controlled`      ENUM('controlled','uncontrolled','unknown') NOT NULL DEFAULT 'unknown',
  `onset_date`      DATE         NULL,
  `note`            VARCHAR(255) NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_comorbidity_case_code` (`case_id`, `comorbidity_code`, `deleted_marker`),
  KEY `idx_comorbidity_code` (`comorbidity_code`),
  CONSTRAINT `fk_comorbidity_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='共病';

CREATE TABLE `infection_status` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `evidence_id`     BIGINT UNSIGNED NULL,
  `hbv_status`      ENUM('POS','NEG','UNK') NOT NULL DEFAULT 'UNK',
  `hbv_dna_iu`      DECIMAL(20,2) NULL,
  `hbv_treated`     TINYINT(1)   NULL,
  `hcv_status`      ENUM('POS','NEG','UNK') NOT NULL DEFAULT 'UNK',
  `hiv_status`      ENUM('POS','NEG','UNK') NOT NULL DEFAULT 'UNK',
  `tb_status`       ENUM('POS','NEG','UNK') NOT NULL DEFAULT 'UNK',
  `last_evaluated_at` DATE       NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_infection_case` (`case_id`),
  CONSTRAINT `fk_infection_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='感染状态（HBV/HCV/HIV/TB）';

-- =============================================================================
-- 模块 I：CRF 字段值（专病字段键值存储）
-- =============================================================================

DROP TABLE IF EXISTS `case_crf_value`;

CREATE TABLE `case_crf_value` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `template_id`     BIGINT UNSIGNED NOT NULL,
  `crf_field_id`    BIGINT UNSIGNED NOT NULL,
  `field_code`      VARCHAR(128) NOT NULL                    COMMENT '冗余 field_code，便于按 code 查询',
  `repeat_idx`      INT          NOT NULL DEFAULT 0          COMMENT 'repeatable 字段的多值序号',
  `value_text`      VARCHAR(1024) NULL,
  `value_number`    DECIMAL(20,6) NULL,
  `value_date`      DATE         NULL,
  `value_datetime`  DATETIME(3)  NULL,
  `value_bool`      TINYINT(1)   NULL,
  `value_code`      VARCHAR(64)  NULL                        COMMENT 'category 类型命中 code_value.code',
  `value_unit`      VARCHAR(32)  NULL,
  `value_json`      JSON         NULL                        COMMENT '复杂结构兜底（数组、对象）',
  `display_value`   VARCHAR(255) NULL                        COMMENT '冗余展示字符串，便于列表/卡片',
  `status`          ENUM('filled','missing','conflict','not_applicable') NOT NULL DEFAULT 'missing',
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'missing',
  `evidence_id`     BIGINT UNSIGNED NULL,
  `event_id`        BIGINT UNSIGNED NULL,
  `last_source_doc_id` BIGINT UNSIGNED NULL                  COMMENT '最近一次写入的来源 document.id',
  `verified_at`     DATETIME(3)  NULL,
  `verified_by`     BIGINT UNSIGNED NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`      BIGINT UNSIGNED NULL,
  `updated_by`      BIGINT UNSIGNED NULL,
  `deleted_at`      DATETIME(3)  NULL DEFAULT NULL,
  `deleted_marker`  BIGINT UNSIGNED NOT NULL
                    DEFAULT 0 COMMENT '软删除标记：活动行=0；软删时由应用层写入毫秒时间戳，与业务键组合保证唯一',
  `is_filled`       TINYINT
                    GENERATED ALWAYS AS (IF(`status` IN ('filled','not_applicable'), 1, 0)) STORED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_crf_value` (`case_id`, `template_id`, `field_code`, `repeat_idx`, `deleted_marker`),
  KEY `idx_crf_value_field_code` (`template_id`, `field_code`, `value_code`),
  KEY `idx_crf_value_field_number` (`template_id`, `field_code`, `value_number`),
  KEY `idx_crf_value_field_date` (`template_id`, `field_code`, `value_date`),
  KEY `idx_crf_value_case_status` (`case_id`, `status`),
  KEY `idx_crf_value_filled` (`case_id`, `is_filled`),
  KEY `idx_crf_value_field_id` (`crf_field_id`),
  CONSTRAINT `fk_crf_value_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_value_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_value_field` FOREIGN KEY (`crf_field_id`) REFERENCES `crf_field` (`id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_value_evidence` FOREIGN KEY (`evidence_id`) REFERENCES `evidence_anchor` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crf_value_event` FOREIGN KEY (`event_id`) REFERENCES `clinical_event` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例 CRF 字段值（按数据类型拆列）';

-- =============================================================================
-- 模块 J：随访
-- =============================================================================

DROP TABLE IF EXISTS `follow_up_record`;
DROP TABLE IF EXISTS `follow_up_plan`;

CREATE TABLE `follow_up_plan` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `plan_name`         VARCHAR(128) NULL,
  `frequency_code`    VARCHAR(32)  NULL                      COMMENT 'monthly / q3m / q6m / yearly / custom',
  `next_due_date`     DATE         NULL,
  `owner_user_id`     BIGINT UNSIGNED NULL,
  `status`            ENUM('active','paused','closed') NOT NULL DEFAULT 'active',
  `description`       VARCHAR(512) NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`        BIGINT UNSIGNED NULL,
  `updated_by`        BIGINT UNSIGNED NULL,
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_followup_plan_case` (`case_id`, `status`),
  KEY `idx_followup_plan_due` (`next_due_date`),
  KEY `idx_followup_plan_owner` (`owner_user_id`),
  CONSTRAINT `fk_followup_plan_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='随访计划';

CREATE TABLE `follow_up_record` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `plan_id`           BIGINT UNSIGNED NULL,
  `event_id`          BIGINT UNSIGNED NULL,
  `follow_up_date`    DATE         NOT NULL,
  `method`            ENUM('phone','clinic','online','wechat','sms','other') NOT NULL DEFAULT 'phone',
  `summary`           TEXT         NULL,
  `disease_status`    VARCHAR(32)  NULL                      COMMENT '继续治疗 / 完全缓解 / 进展 / 失访 / 死亡',
  `next_due_date`     DATE         NULL,
  `attachment_doc_id` BIGINT UNSIGNED NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`        BIGINT UNSIGNED NULL,
  `updated_by`        BIGINT UNSIGNED NULL,
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_followup_record_case_date` (`case_id`, `follow_up_date`),
  KEY `idx_followup_record_plan` (`plan_id`),
  CONSTRAINT `fk_followup_record_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_followup_record_plan` FOREIGN KEY (`plan_id`) REFERENCES `follow_up_plan` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_followup_record_doc` FOREIGN KEY (`attachment_doc_id`) REFERENCES `document` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='随访记录';

-- =============================================================================
-- 模块 K：上传 / 抽取审核
-- =============================================================================

DROP TABLE IF EXISTS `upload_review_decision`;
DROP TABLE IF EXISTS `extraction_detail`;
DROP TABLE IF EXISTS `upload_job`;

CREATE TABLE `upload_job` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `job_uid`           CHAR(32)     NOT NULL,
  `patient_id`        BIGINT UNSIGNED NULL                   COMMENT '上传时可能未关联到患者，可空',
  `case_id`           BIGINT UNSIGNED NULL,
  `document_id`       BIGINT UNSIGNED NULL                   COMMENT '解析后绑定 document',
  `template_id`       BIGINT UNSIGNED NULL,
  `source`            ENUM('camera','pdf','voice','gallery','api') NOT NULL,
  `stage`             ENUM('queued','processing','extracted','needs_review','completed','failed') NOT NULL DEFAULT 'queued',
  `document_type`     VARCHAR(64)  NULL                      COMMENT '用户/AI 识别的文档类型展示名',
  `description`       VARCHAR(512) NULL,
  `extracted_highlights` JSON      NULL                      COMMENT '前端用的高亮字段简表',
  `pending_review_fields` JSON     NULL                      COMMENT '待审核字段名列表',
  `extraction_payload` JSON        NULL                      COMMENT 'AI 抽取原始结果（含模型版本、置信度等）',
  `error_message`     VARCHAR(1024) NULL,
  `submitted_by`      BIGINT UNSIGNED NULL,
  `reviewed_by`       BIGINT UNSIGNED NULL,
  `reviewed_at`       DATETIME(3)  NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_upload_job_uid` (`job_uid`),
  KEY `idx_upload_job_stage` (`stage`, `created_at`),
  KEY `idx_upload_job_case` (`case_id`),
  KEY `idx_upload_job_patient` (`patient_id`),
  KEY `idx_upload_job_document` (`document_id`),
  KEY `idx_upload_job_submitter` (`submitted_by`, `created_at`),
  CONSTRAINT `fk_upload_job_patient` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_upload_job_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_upload_job_document` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_upload_job_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='上传任务（采集 -> 抽取 -> 审核）';

CREATE TABLE `extraction_detail` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `upload_job_id`     BIGINT UNSIGNED NOT NULL,
  `case_id`           BIGINT UNSIGNED NULL,
  `template_id`       BIGINT UNSIGNED NULL,
  `crf_field_id`      BIGINT UNSIGNED NULL,
  `field_code`        VARCHAR(128) NULL,
  `field_path`        VARCHAR(512) NULL,
  `field_name`        VARCHAR(128) NOT NULL                  COMMENT '展示用字段名（可能未命中模板时仍记录）',
  `value`             VARCHAR(1024) NOT NULL,
  `confidence`        ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `change_type`       ENUM('append','fill','update','conflict','unchanged') NOT NULL DEFAULT 'append',
  `existing_value`    VARCHAR(1024) NULL,
  `existing_field_id` BIGINT UNSIGNED NULL                   COMMENT '指向 case_crf_value.id 或 L2 事实 id',
  `evidence_id`       BIGINT UNSIGNED NULL,
  `source_locator`    VARCHAR(255) NULL                      COMMENT '页码/时间戳/坐标',
  `source_excerpt`    VARCHAR(1024) NULL,
  `canonical_impact`  VARCHAR(255) NULL                      COMMENT '主干回写预览，例如 Stage.tnm_t = T2',
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_extract_detail_job` (`upload_job_id`),
  KEY `idx_extract_detail_field_code` (`template_id`, `field_code`),
  KEY `idx_extract_detail_case` (`case_id`),
  CONSTRAINT `fk_extract_detail_job` FOREIGN KEY (`upload_job_id`) REFERENCES `upload_job` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_extract_detail_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_extract_detail_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='上传审核行（AI 抽取候选）';

CREATE TABLE `upload_review_decision` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `upload_job_id`     BIGINT UNSIGNED NOT NULL,
  `extraction_id`     BIGINT UNSIGNED NOT NULL,
  `decision`          ENUM('accept_new','keep_old','mark_conflict','mark_not_applicable','remap_field') NOT NULL,
  `remapped_field_code` VARCHAR(128) NULL                    COMMENT '改绑字段时的新 field_code',
  `note`              VARCHAR(512) NULL,
  `decided_by`        BIGINT UNSIGNED NULL,
  `decided_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_review_decision_job` (`upload_job_id`),
  KEY `idx_review_decision_extract` (`extraction_id`),
  CONSTRAINT `fk_review_decision_job` FOREIGN KEY (`upload_job_id`) REFERENCES `upload_job` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_review_decision_extract` FOREIGN KEY (`extraction_id`) REFERENCES `extraction_detail` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='上传审核决策日志';

-- =============================================================================
-- 模块 L：筛查 / YABY 快照 / 任务
-- =============================================================================

DROP TABLE IF EXISTS `task_conflict_entry`;
DROP TABLE IF EXISTS `completeness_task`;
DROP TABLE IF EXISTS `case_screening_status`;
DROP TABLE IF EXISTS `screening_project`;
DROP TABLE IF EXISTS `yaby_snapshot`;

CREATE TABLE `yaby_snapshot` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `snapshot_uid`        CHAR(32)     NOT NULL,
  `case_id`             BIGINT UNSIGNED NOT NULL,
  `snapshot_version`    INT          NOT NULL DEFAULT 1     COMMENT '同病例递增',
  `min_fields_version`  VARCHAR(32)  NOT NULL                COMMENT 'YABY 最小字段集 Schema 版本',
  `payload`             JSON         NOT NULL                COMMENT '完整快照（瘤种/分期/线数/标志物/检验/ECOG/共病/禁忌等）',
  `core_completion_rate` DECIMAL(5,4) NOT NULL DEFAULT 0,
  `crf_completion_rate` DECIMAL(5,4) NOT NULL DEFAULT 0,
  `status`              ENUM('not_ready','partial','ready') NOT NULL DEFAULT 'not_ready',
  `computed_at`         DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `computed_by`         VARCHAR(64)  NULL                    COMMENT '触发者：system / user_id / job_id',
  `created_at`          DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_yaby_snapshot_uid` (`snapshot_uid`),
  UNIQUE KEY `uk_yaby_case_version` (`case_id`, `snapshot_version`),
  KEY `idx_yaby_case_status` (`case_id`, `status`, `computed_at`),
  CONSTRAINT `fk_yaby_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='YABY 小丫筛查快照（不可变历史）';

CREATE TABLE `screening_project` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `project_uid`       CHAR(32)     NOT NULL,
  `code`              VARCHAR(64)  NOT NULL                  COMMENT '项目 code',
  `title`             VARCHAR(255) NOT NULL,
  `sponsor`           VARCHAR(128) NULL,
  `disease_profile_id` BIGINT UNSIGNED NULL,
  `status`            ENUM('recruiting','closed','paused') NOT NULL DEFAULT 'recruiting',
  `eligibility_version` VARCHAR(32) NULL,
  `eligibility_rules` JSON         NULL                      COMMENT '入排规则 DSL',
  `description`       TEXT         NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`        BIGINT UNSIGNED NULL,
  `updated_by`        BIGINT UNSIGNED NULL,
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_screening_project_uid` (`project_uid`),
  UNIQUE KEY `uk_screening_project_code` (`code`),
  KEY `idx_screening_project_profile` (`disease_profile_id`),
  CONSTRAINT `fk_screening_project_profile` FOREIGN KEY (`disease_profile_id`) REFERENCES `disease_profile` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='筛查 / 临床研究项目';

CREATE TABLE `case_screening_status` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `project_id`        BIGINT UNSIGNED NOT NULL,
  `snapshot_id`       BIGINT UNSIGNED NULL                   COMMENT '当前评估基于的 yaby_snapshot.id',
  `status`            ENUM('not_ready','partial','ready','enrolled','excluded') NOT NULL DEFAULT 'not_ready',
  `reason`            VARCHAR(512) NULL,
  `last_evaluated_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_project` (`case_id`, `project_id`),
  KEY `idx_case_screening_project` (`project_id`, `status`),
  CONSTRAINT `fk_css_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_css_project` FOREIGN KEY (`project_id`) REFERENCES `screening_project` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_css_snapshot` FOREIGN KEY (`snapshot_id`) REFERENCES `yaby_snapshot` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例 × 项目 入选状态';

CREATE TABLE `completeness_task` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_uid`          CHAR(32)     NOT NULL,
  `case_id`           BIGINT UNSIGNED NOT NULL,
  `project_id`        BIGINT UNSIGNED NULL                   COMMENT '可空，部分任务非项目驱动',
  `template_id`       BIGINT UNSIGNED NULL,
  `field_code`        VARCHAR(128) NULL,
  `field_path`        VARCHAR(512) NULL,
  `crf_field_id`      BIGINT UNSIGNED NULL,
  `type`              ENUM('missing_field','conflict_review','governance','template_migration') NOT NULL,
  `scope`             ENUM('canonical','crf','governance') NOT NULL DEFAULT 'canonical',
  `title`             VARCHAR(255) NOT NULL,
  `description`       TEXT         NULL,
  `fields`            JSON         NULL                      COMMENT '一次任务覆盖的字段名列表（展示用）',
  `is_blocking`       TINYINT(1)   NOT NULL DEFAULT 0,
  `is_completed`      TINYINT(1)   NOT NULL DEFAULT 0,
  `owner_user_id`     BIGINT UNSIGNED NULL,
  `due_at`            DATETIME(3)  NULL,
  `completed_at`      DATETIME(3)  NULL,
  `completed_by`      BIGINT UNSIGNED NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `created_by`        BIGINT UNSIGNED NULL,
  `updated_by`        BIGINT UNSIGNED NULL,
  `deleted_at`        DATETIME(3)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_completeness_task_uid` (`task_uid`),
  KEY `idx_task_case_completed` (`case_id`, `is_completed`),
  KEY `idx_task_owner_due` (`owner_user_id`, `due_at`),
  KEY `idx_task_type_scope` (`type`, `scope`),
  KEY `idx_task_field_code` (`template_id`, `field_code`),
  CONSTRAINT `fk_task_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_task_project` FOREIGN KEY (`project_id`) REFERENCES `screening_project` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_task_template` FOREIGN KEY (`template_id`) REFERENCES `crf_template` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='缺字段 / 冲突核对任务';

CREATE TABLE `task_conflict_entry` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `task_id`       BIGINT UNSIGNED NOT NULL,
  `field_label`   VARCHAR(128) NOT NULL,
  `source_a`      VARCHAR(128) NOT NULL                    COMMENT '来源 A：例如 出院小结 P3',
  `value_a`       VARCHAR(255) NOT NULL,
  `evidence_id_a` BIGINT UNSIGNED NULL,
  `source_b`      VARCHAR(128) NOT NULL,
  `value_b`       VARCHAR(255) NOT NULL,
  `evidence_id_b` BIGINT UNSIGNED NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_task_conflict_task` (`task_id`),
  CONSTRAINT `fk_task_conflict_task` FOREIGN KEY (`task_id`) REFERENCES `completeness_task` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='冲突任务的多源对照';

-- =============================================================================
-- 模块 M：检索投影 / 关系表
-- =============================================================================

DROP TABLE IF EXISTS `case_search_index`;
DROP TABLE IF EXISTS `case_tag`;
DROP TABLE IF EXISTS `case_disease_group`;
DROP TABLE IF EXISTS `document_field_link`;

CREATE TABLE `case_search_index` (
  `id`                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`                  BIGINT UNSIGNED NOT NULL,
  `disease_profile_id`       BIGINT UNSIGNED NOT NULL,
  `crf_template_id`          BIGINT UNSIGNED NOT NULL,
  `disease_group_code`       VARCHAR(32)  NOT NULL,
  `tumor_code`               VARCHAR(32)  NOT NULL,
  `primary_site_code`        VARCHAR(32)  NULL,
  `tumor_type`               VARCHAR(64)  NULL,
  `histology`                VARCHAR(128) NULL,
  `stage_label`              VARCHAR(32)  NULL,
  `line_of_therapy`          TINYINT      NULL,
  `current_regimen_type`     VARCHAR(32)  NULL,
  `key_drug_classes`         JSON         NULL                COMMENT '近 1 年涉及的药物类别集合',
  `pdl1_value_text`          VARCHAR(64)  NULL,
  `msi_status`               VARCHAR(32)  NULL,
  `recent_alt`               DECIMAL(20,6) NULL,
  `recent_ast`               DECIMAL(20,6) NULL,
  `recent_tbil`              DECIMAL(20,6) NULL,
  `recent_anc`               DECIMAL(20,6) NULL,
  `has_liver_risk`           TINYINT(1)   NOT NULL DEFAULT 0,
  `ecog`                     TINYINT      NULL,
  `comorbidity_codes`        JSON         NULL,
  `tags`                     JSON         NULL,
  `screening_status`         ENUM('not_ready','partial','ready') NOT NULL DEFAULT 'not_ready',
  `core_completion_rate`     DECIMAL(5,4) NOT NULL DEFAULT 0,
  `crf_completion_rate`      DECIMAL(5,4) NOT NULL DEFAULT 0,
  `last_event_at`            DATETIME(3)  NULL,
  `last_indexed_at`          DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_search_case` (`case_id`),
  KEY `idx_csi_profile_status` (`disease_profile_id`, `screening_status`),
  KEY `idx_csi_group_stage` (`disease_group_code`, `stage_label`),
  KEY `idx_csi_regimen_liver` (`current_regimen_type`, `has_liver_risk`),
  KEY `idx_csi_ecog` (`ecog`),
  KEY `idx_csi_template_completion` (`crf_template_id`, `crf_completion_rate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例检索投影表（一行一病例，应用层维护）';

CREATE TABLE `case_tag` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`       BIGINT UNSIGNED NOT NULL,
  `tag_code`      VARCHAR(64)  NOT NULL                    COMMENT '字典 Tag 中的 code',
  `tag_label`     VARCHAR(64)  NOT NULL,
  `source`        ENUM('ai','rule','manual') NOT NULL DEFAULT 'rule',
  `confidence`    ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_by`    BIGINT UNSIGNED NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_tag` (`case_id`, `tag_code`),
  KEY `idx_case_tag_code` (`tag_code`),
  CONSTRAINT `fk_case_tag_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例标签';

CREATE TABLE `case_disease_group` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`       BIGINT UNSIGNED NOT NULL,
  `group_code`    VARCHAR(32)  NOT NULL                    COMMENT '疾病组 code（GU / LUNG / BREAST / RARE 等）',
  `group_name`    VARCHAR(64)  NOT NULL,
  `is_primary`    TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_group` (`case_id`, `group_code`),
  KEY `idx_case_group_code` (`group_code`),
  CONSTRAINT `fk_case_group_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='病例疾病组（一对多）';

CREATE TABLE `document_field_link` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `document_id`   BIGINT UNSIGNED NOT NULL,
  `case_id`       BIGINT UNSIGNED NOT NULL,
  `template_id`   BIGINT UNSIGNED NULL,
  `field_code`    VARCHAR(128) NULL,
  `crf_field_id`  BIGINT UNSIGNED NULL,
  `crf_value_id`  BIGINT UNSIGNED NULL,
  `evidence_id`   BIGINT UNSIGNED NULL,
  `is_confirmed`  TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '人工是否确认',
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_dfl_doc` (`document_id`, `is_confirmed`),
  KEY `idx_dfl_case_field` (`case_id`, `template_id`, `field_code`),
  KEY `idx_dfl_value` (`crf_value_id`),
  CONSTRAINT `fk_dfl_doc` FOREIGN KEY (`document_id`) REFERENCES `document` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dfl_case` FOREIGN KEY (`case_id`) REFERENCES `case` (`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='文档命中字段记录';

-- =============================================================================
-- 模块 N：审计 / 日志（不软删）
-- =============================================================================

DROP TABLE IF EXISTS `phi_access_log`;
DROP TABLE IF EXISTS `deid_mapping`;
DROP TABLE IF EXISTS `export_log`;
DROP TABLE IF EXISTS `field_change_log`;
DROP TABLE IF EXISTS `audit_log`;

CREATE TABLE `audit_log` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_user_id` BIGINT UNSIGNED NULL,
  `actor_name`    VARCHAR(64)  NULL,
  `action`        ENUM('VIEW','EXPORT','EDIT','DELETE','CREATE','LOGIN','LOGOUT','REVIEW') NOT NULL,
  `target_table`  VARCHAR(64)  NOT NULL,
  `target_id`     BIGINT UNSIGNED NULL,
  `target_uid`    VARCHAR(64)  NULL,
  `case_id`       BIGINT UNSIGNED NULL                    COMMENT '冗余 case_id 便于按病例聚合审计',
  `request_id`    VARCHAR(64)  NULL,
  `ip`            VARCHAR(45)  NULL,
  `user_agent`    VARCHAR(255) NULL,
  `diff`          JSON         NULL                      COMMENT '变更前后 diff 摘要',
  `note`          VARCHAR(512) NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_audit_target` (`target_table`, `target_id`, `created_at`),
  KEY `idx_audit_actor` (`actor_user_id`, `created_at`),
  KEY `idx_audit_case` (`case_id`, `created_at`),
  KEY `idx_audit_action` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='通用审计日志（建议按月分区，TODO）';

CREATE TABLE `field_change_log` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `case_id`         BIGINT UNSIGNED NOT NULL,
  `target_kind`     ENUM('crf_value','canonical_fact') NOT NULL,
  `target_table`    VARCHAR(64)  NOT NULL                    COMMENT 'crf_value 时记 case_crf_value；canonical_fact 时记具体 L2 表名',
  `target_id`       BIGINT UNSIGNED NOT NULL,
  `template_id`     BIGINT UNSIGNED NULL,
  `field_code`      VARCHAR(128) NULL,
  `field_label`     VARCHAR(128) NULL,
  `before_value`    JSON         NULL,
  `after_value`     JSON         NULL,
  `change_type`     ENUM('append','fill','update','conflict','delete','revert') NOT NULL,
  `confidence`      ENUM('verified','ai_high','ai_medium','missing','conflict') NOT NULL DEFAULT 'ai_medium',
  `evidence_id`     BIGINT UNSIGNED NULL,
  `source_doc_id`   BIGINT UNSIGNED NULL,
  `actor_user_id`   BIGINT UNSIGNED NULL,
  `actor_kind`      ENUM('user','ai','system','rule') NOT NULL DEFAULT 'user',
  `note`            VARCHAR(512) NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_fcl_case` (`case_id`, `created_at`),
  KEY `idx_fcl_target` (`target_table`, `target_id`),
  KEY `idx_fcl_field` (`template_id`, `field_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='字段变更明细（CRF 值 / 主干字段值）';

CREATE TABLE `export_log` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `export_uid`        CHAR(32)     NOT NULL,
  `actor_user_id`     BIGINT UNSIGNED NOT NULL,
  `case_count`        INT          NOT NULL DEFAULT 0,
  `field_set_version` VARCHAR(32)  NULL,
  `deid_strategy`     JSON         NULL                      COMMENT '脱敏策略（哪些字段做哪种处理）',
  `purpose`           VARCHAR(255) NULL,
  `output_uri`        VARCHAR(1024) NULL,
  `status`            ENUM('pending','running','succeeded','failed','revoked') NOT NULL DEFAULT 'pending',
  `error_message`     VARCHAR(1024) NULL,
  `started_at`        DATETIME(3)  NULL,
  `finished_at`       DATETIME(3)  NULL,
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_export_uid` (`export_uid`),
  KEY `idx_export_actor` (`actor_user_id`, `created_at`),
  KEY `idx_export_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='科研脱敏导出记录';

CREATE TABLE `deid_mapping` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `entity_kind`     ENUM('patient','document','case','user') NOT NULL,
  `real_id`         BIGINT UNSIGNED NOT NULL,
  `deid_id`         CHAR(32)     NOT NULL                    COMMENT '脱敏 id（UUID 或哈希）',
  `salt`            CHAR(32)     NOT NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_deid_entity_real` (`entity_kind`, `real_id`),
  UNIQUE KEY `uk_deid_entity_deid` (`entity_kind`, `deid_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='脱敏映射（建议物理隔离到独立高敏库，TODO）';

CREATE TABLE `phi_access_log` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_user_id`   BIGINT UNSIGNED NOT NULL,
  `entity_kind`     ENUM('patient','document','case') NOT NULL,
  `entity_id`       BIGINT UNSIGNED NOT NULL,
  `phi_fields`      JSON         NOT NULL                    COMMENT '本次访问的 PHI 字段名列表',
  `purpose`         VARCHAR(255) NULL,
  `request_id`      VARCHAR(64)  NULL,
  `ip`              VARCHAR(45)  NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_phi_log_actor` (`actor_user_id`, `created_at`),
  KEY `idx_phi_log_entity` (`entity_kind`, `entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci ROW_FORMAT=DYNAMIC COMMENT='PHI 字段访问审计';

-- =============================================================================
-- 收尾
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- 建议在 disease_profile 表创建后，通过 ALTER 补充 default_template_id 的软外键：
--   ALTER TABLE `disease_profile`
--     ADD CONSTRAINT `fk_disease_profile_default_template`
--     FOREIGN KEY (`default_template_id`) REFERENCES `crf_template` (`id`)
--     ON DELETE SET NULL ON UPDATE CASCADE;
-- 当前版本未启用，避免 disease_profile <-> crf_template 循环 DDL 顺序问题。
