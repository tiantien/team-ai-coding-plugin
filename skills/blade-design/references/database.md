# 数据库建表语句生成参考

本文档包含 BladeX 支持的 7 种数据库方言的建表模板。所有模板均来源于 BladeX 真实 SQL 脚本。

## 目录
- [一、通用审计字段](#一通用审计字段)
- [二、字段类型映射表](#二字段类型映射表)
- [三、MySQL 建表模板](#三mysql-建表模板)
- [四、PostgreSQL 建表模板](#四postgresql-建表模板)
- [五、Oracle 建表模板](#五oracle-建表模板)
- [六、SQL Server 建表模板](#六sql-server-建表模板)
- [七、达梦 建表模板](#七达梦-建表模板)
- [八、人大金仓 建表模板](#八人大金仓-建表模板)
- [九、崖山 建表模板](#九崖山-建表模板)
- [十、菜单 SQL 生成](#十菜单-sql-生成)

---

## 一、通用审计字段

所有继承 `TenantEntity` 或 `BaseEntity` 的业务表都包含以下固定审计字段：

| 字段名 | 说明 | Java 类型 | 是否可空 | 默认值 |
|--------|------|-----------|----------|--------|
| `id` | 主键（雪花 ID） | Long | NOT NULL | 无 |
| `tenant_id` | 租户 ID（仅 TenantEntity） | String | NULL | '000000' |
| `create_user` | 创建人 | Long | NULL | NULL |
| `create_dept` | 创建部门 | Long | NULL | NULL |
| `create_time` | 创建时间 | Date | NULL | NULL |
| `update_user` | 修改人 | Long | NULL | NULL |
| `update_time` | 修改时间 | Date | NULL | NULL |
| `status` | 业务状态 | Integer | NULL | 1 |
| `is_deleted` | 逻辑删除标记 | Integer | NULL | 0 |

**BaseEntity 模式**不包含 `tenant_id` 字段。
**Raw Serializable 模式**手动定义全部字段（结构相同）。

---

## 二、字段类型映射表

### Java 类型 → 数据库类型映射

| Java 类型 | MySQL | PostgreSQL | Oracle | SQL Server | 达梦 | 人大金仓 | 崖山 |
|-----------|-------|------------|--------|------------|------|---------|------|
| `String` (短) | `varchar(n)` | `varchar(n)` | `VARCHAR2(n BYTE)` | `nvarchar(n)` | `VARCHAR2(n)` | `varchar(n)` | `VARCHAR2(n BYTE)` |
| `String` (长) | `text` | `text` | `NCLOB` | `text` | `CLOB` | `text` | `NCLOB` |
| `Integer` | `int` | `int4` | `NUMBER(11,0)` | `int` | `INT` | `int4` | `NUMBER(11,0)` |
| `Long` | `bigint` | `int8` | `NUMBER(20,0)` | `bigint` | `BIGINT` | `int8` | `NUMBER(20,0)` |
| `Double` | `double` | `float8` | `NUMBER` | `float` | `DOUBLE` | `float8` | `NUMBER` |
| `BigDecimal` | `decimal(m,n)` | `numeric(m,n)` | `NUMBER(m,n)` | `decimal(m,n)` | `DECIMAL(m,n)` | `numeric(m,n)` | `NUMBER(m,n)` |
| `Date` | `datetime` | `timestamp(6)` | `DATE` | `datetime` | `DATETIME` | `timestamp(6)` | `DATE` |
| `Boolean` | `tinyint(1)` | `bool` | `NUMBER(1,0)` | `bit` | `BIT` | `bool` | `NUMBER(1,0)` |

### 通用审计字段各方言定义

| 字段 | MySQL | PostgreSQL | Oracle | SQL Server |
|------|-------|------------|--------|------------|
| id | `bigint NOT NULL` | `int8 NOT NULL` | `NUMBER(20,0) NOT NULL` | `bigint NOT NULL` |
| tenant_id | `varchar(12) DEFAULT '000000'` | `varchar(12) DEFAULT '000000'` | `NVARCHAR2(12)` | `nvarchar(12) DEFAULT '000000'` |
| create_user | `bigint NULL` | `int8` | `NUMBER(20,0)` | `bigint NULL` |
| create_dept | `bigint NULL` | `int8` | `NUMBER(20,0)` | `bigint NULL` |
| create_time | `datetime NULL` | `timestamp(6)` | `DATE` | `datetime NULL` |
| update_user | `bigint NULL` | `int8` | `NUMBER(20,0)` | `bigint NULL` |
| update_time | `datetime NULL` | `timestamp(6)` | `DATE` | `datetime NULL` |
| status | `int DEFAULT 1` | `int4 DEFAULT 1` | `NUMBER(11,0) DEFAULT 1` | `int DEFAULT 1` |
| is_deleted | `int DEFAULT 0` | `int4 DEFAULT 0` | `NUMBER(11,0) DEFAULT 0` | `int DEFAULT 0` |

---

## 三、MySQL 建表模板

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for blade_{table_name}
-- ----------------------------
DROP TABLE IF EXISTS `blade_{table_name}`;
CREATE TABLE `blade_{table_name}`  (
  `id` bigint NOT NULL COMMENT '主键',
  `tenant_id` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '000000' COMMENT '租户ID',
  -- 业务字段
  `{column_name}` {mysql_type} {null_constraint} {default_value} COMMENT '{字段注释}',
  -- 审计字段
  `create_user` bigint NULL DEFAULT NULL COMMENT '创建人',
  `create_dept` bigint NULL DEFAULT NULL COMMENT '创建部门',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_user` bigint NULL DEFAULT NULL COMMENT '修改人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `status` int NULL DEFAULT 1 COMMENT '状态',
  `is_deleted` int NULL DEFAULT 0 COMMENT '是否已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '{表注释}';

SET FOREIGN_KEY_CHECKS = 1;
```

**MySQL 特点**：
- 列名使用反引号 `` ` `` 包裹
- 注释直接用 `COMMENT` 关键字写在列定义后
- 表注释在 CREATE TABLE 末尾
- 字符集指定 `utf8mb4`
- 引擎 `InnoDB`
- 主键索引类型 `USING BTREE`

---

## 四、PostgreSQL 建表模板

```sql
-- ----------------------------
-- Table structure for blade_{table_name}
-- ----------------------------
DROP TABLE IF EXISTS "blade_{table_name}";
CREATE TABLE "blade_{table_name}" (
  "id" int8 NOT NULL,
  "tenant_id" varchar(12) COLLATE "pg_catalog"."default" DEFAULT '000000'::character varying,
  -- 业务字段
  "{column_name}" {pg_type} {collate_clause} {default_value},
  -- 审计字段
  "create_user" int8,
  "create_dept" int8,
  "create_time" timestamp(6),
  "update_user" int8,
  "update_time" timestamp(6),
  "status" int4 DEFAULT 1,
  "is_deleted" int4 DEFAULT 0
);

-- ----------------------------
-- Comments
-- ----------------------------
COMMENT ON COLUMN "blade_{table_name}"."id" IS '主键';
COMMENT ON COLUMN "blade_{table_name}"."tenant_id" IS '租户ID';
COMMENT ON COLUMN "blade_{table_name}"."{column_name}" IS '{字段注释}';
COMMENT ON COLUMN "blade_{table_name}"."create_user" IS '创建人';
COMMENT ON COLUMN "blade_{table_name}"."create_dept" IS '创建部门';
COMMENT ON COLUMN "blade_{table_name}"."create_time" IS '创建时间';
COMMENT ON COLUMN "blade_{table_name}"."update_user" IS '修改人';
COMMENT ON COLUMN "blade_{table_name}"."update_time" IS '修改时间';
COMMENT ON COLUMN "blade_{table_name}"."status" IS '状态';
COMMENT ON COLUMN "blade_{table_name}"."is_deleted" IS '是否已删除';
COMMENT ON TABLE "blade_{table_name}" IS '{表注释}';

-- ----------------------------
-- Primary Key
-- ----------------------------
ALTER TABLE "blade_{table_name}" ADD CONSTRAINT "blade_{table_name}_pkey" PRIMARY KEY ("id");
```

**PostgreSQL 特点**：
- 列名使用双引号 `"` 包裹
- 注释使用 `COMMENT ON COLUMN/TABLE` 语句（CREATE 之后）
- varchar 字段需要 `COLLATE "pg_catalog"."default"`
- 默认值带类型转换 `'000000'::character varying`
- 时间类型用 `timestamp(6)`
- 主键通过 `ALTER TABLE` 添加

---

## 五、Oracle 建表模板

```sql
-- ----------------------------
-- Table structure for BLADE_{TABLE_NAME}
-- ----------------------------
CREATE TABLE "BLADE_{TABLE_NAME}" (
  "ID" NUMBER(20,0) NOT NULL,
  "TENANT_ID" NVARCHAR2(12),
  -- 业务字段
  "{COLUMN_NAME}" {oracle_type},
  -- 审计字段
  "CREATE_USER" NUMBER(20,0),
  "CREATE_DEPT" NUMBER(20,0),
  "CREATE_TIME" DATE,
  "UPDATE_USER" NUMBER(20,0),
  "UPDATE_TIME" DATE,
  "STATUS" NUMBER(11,0) DEFAULT 1,
  "IS_DELETED" NUMBER(11,0) DEFAULT 0
)
LOGGING
NOCOMPRESS
PCTFREE 10
INITRANS 1
STORAGE (
  BUFFER_POOL DEFAULT
)
PARALLEL 1
NOCACHE
DISABLE ROW MOVEMENT
;

-- ----------------------------
-- Comments
-- ----------------------------
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."ID" IS '主键';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."TENANT_ID" IS '租户ID';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."{COLUMN_NAME}" IS '{字段注释}';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_USER" IS '创建人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_DEPT" IS '创建部门';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_TIME" IS '创建时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_USER" IS '修改人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_TIME" IS '修改时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."STATUS" IS '状态';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."IS_DELETED" IS '是否已删除';
COMMENT ON TABLE "BLADE_{TABLE_NAME}" IS '{表注释}';

-- ----------------------------
-- Primary Key
-- ----------------------------
ALTER TABLE "BLADE_{TABLE_NAME}" ADD CONSTRAINT "SYS_C00{xxxxx}" PRIMARY KEY ("ID");
```

**Oracle 特点**：
- 表名和列名全部**大写**
- 列名使用双引号 `"` 包裹
- 字符串用 `VARCHAR2(n BYTE)` 或 `NVARCHAR2(n)`
- 数字用 `NUMBER(m,n)`
- 时间用 `DATE`
- 大文本用 `NCLOB`
- 注释用 `COMMENT ON` 语句
- 包含存储参数（LOGGING、NOCOMPRESS、PCTFREE 等）

---

## 六、SQL Server 建表模板

```sql
-- ----------------------------
-- Table structure for blade_{table_name}
-- ----------------------------
IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID(N'[dbo].[blade_{table_name}]') AND type IN ('U'))
    DROP TABLE [dbo].[blade_{table_name}]
GO

CREATE TABLE [dbo].[blade_{table_name}] (
  [id] bigint  NOT NULL,
  [tenant_id] nvarchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT '000000' NULL,
  -- 业务字段
  [{column_name}] {sqlserver_type} {collate_clause} {null_constraint},
  -- 审计字段
  [create_user] bigint  NULL,
  [create_dept] bigint  NULL,
  [create_time] datetime  NULL,
  [update_user] bigint  NULL,
  [update_time] datetime  NULL,
  [status] int DEFAULT 1 NULL,
  [is_deleted] int DEFAULT 0 NULL
)
GO

ALTER TABLE [dbo].[blade_{table_name}] SET (LOCK_ESCALATION = TABLE)
GO

-- ----------------------------
-- Comments
-- ----------------------------
EXEC sp_addextendedproperty
'MS_Description', N'主键',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'id'
GO

EXEC sp_addextendedproperty
'MS_Description', N'租户ID',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'tenant_id'
GO

EXEC sp_addextendedproperty
'MS_Description', N'{字段注释}',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'{column_name}'
GO

-- 审计字段注释...
EXEC sp_addextendedproperty
'MS_Description', N'创建人',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'create_user'
GO

EXEC sp_addextendedproperty
'MS_Description', N'创建部门',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'create_dept'
GO

EXEC sp_addextendedproperty
'MS_Description', N'创建时间',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'create_time'
GO

EXEC sp_addextendedproperty
'MS_Description', N'修改人',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'update_user'
GO

EXEC sp_addextendedproperty
'MS_Description', N'修改时间',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'update_time'
GO

EXEC sp_addextendedproperty
'MS_Description', N'状态',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'status'
GO

EXEC sp_addextendedproperty
'MS_Description', N'是否已删除',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}',
'COLUMN', N'is_deleted'
GO

EXEC sp_addextendedproperty
'MS_Description', N'{表注释}',
'SCHEMA', N'dbo',
'TABLE', N'blade_{table_name}'
GO

-- ----------------------------
-- Primary Key
-- ----------------------------
ALTER TABLE [dbo].[blade_{table_name}] ADD CONSTRAINT [PK__blade_{short}__id] PRIMARY KEY CLUSTERED ([id])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
ON [PRIMARY]
GO
```

**SQL Server 特点**：
- 列名使用方括号 `[]` 包裹
- 每条语句后用 `GO` 分隔
- DROP 前用 `IF EXISTS` 检查
- 字符串用 `nvarchar(n)` + `COLLATE SQL_Latin1_General_CP1_CI_AS`
- 大文本用 `text` 或 `nvarchar(max)`
- 注释用 `sp_addextendedproperty` 存储过程
- Schema 为 `dbo`

---

## 七、达梦 建表模板

```sql
CREATE TABLE "BLADE_{TABLE_NAME}" (
  "ID" BIGINT NOT NULL,
  "TENANT_ID" VARCHAR2(12) DEFAULT '000000',
  -- 业务字段
  "{COLUMN_NAME}" {dameng_type} {default_value},
  -- 审计字段
  "CREATE_USER" BIGINT,
  "CREATE_DEPT" BIGINT,
  "CREATE_TIME" DATETIME,
  "UPDATE_USER" BIGINT,
  "UPDATE_TIME" DATETIME,
  "STATUS" INT DEFAULT 1,
  "IS_DELETED" INT DEFAULT 0
);

COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."ID" IS '主键';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."TENANT_ID" IS '租户ID';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."{COLUMN_NAME}" IS '{字段注释}';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_USER" IS '创建人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_DEPT" IS '创建部门';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_TIME" IS '创建时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_USER" IS '修改人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_TIME" IS '修改时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."STATUS" IS '状态';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."IS_DELETED" IS '是否已删除';
COMMENT ON TABLE "BLADE_{TABLE_NAME}" IS '{表注释}';

ALTER TABLE "BLADE_{TABLE_NAME}" ADD CONSTRAINT "PK_BLADE_{TABLE_NAME}" PRIMARY KEY ("ID");
```

**达梦特点**：
- 语法接近 Oracle
- 表名列名大写 + 双引号
- 支持 `BIGINT`、`INT`（Oracle 用 NUMBER）
- 时间用 `DATETIME`（Oracle 用 DATE）
- 大文本用 `CLOB`
- 注释用 `COMMENT ON`

---

## 八、人大金仓 建表模板

```sql
DROP TABLE IF EXISTS "blade_{table_name}";
CREATE TABLE "blade_{table_name}" (
  "id" int8 NOT NULL,
  "tenant_id" varchar(12) COLLATE "pg_catalog"."default" DEFAULT '000000'::character varying,
  -- 业务字段
  "{column_name}" {kingbase_type} {collate_clause} {default_value},
  -- 审计字段
  "create_user" int8,
  "create_dept" int8,
  "create_time" timestamp(6),
  "update_user" int8,
  "update_time" timestamp(6),
  "status" int4 DEFAULT 1,
  "is_deleted" int4 DEFAULT 0
);

COMMENT ON COLUMN "blade_{table_name}"."id" IS '主键';
COMMENT ON COLUMN "blade_{table_name}"."tenant_id" IS '租户ID';
COMMENT ON COLUMN "blade_{table_name}"."{column_name}" IS '{字段注释}';
COMMENT ON COLUMN "blade_{table_name}"."create_user" IS '创建人';
COMMENT ON COLUMN "blade_{table_name}"."create_dept" IS '创建部门';
COMMENT ON COLUMN "blade_{table_name}"."create_time" IS '创建时间';
COMMENT ON COLUMN "blade_{table_name}"."update_user" IS '修改人';
COMMENT ON COLUMN "blade_{table_name}"."update_time" IS '修改时间';
COMMENT ON COLUMN "blade_{table_name}"."status" IS '状态';
COMMENT ON COLUMN "blade_{table_name}"."is_deleted" IS '是否已删除';
COMMENT ON TABLE "blade_{table_name}" IS '{表注释}';

ALTER TABLE "blade_{table_name}" ADD CONSTRAINT "blade_{table_name}_pkey" PRIMARY KEY ("id");
```

**人大金仓特点**：
- 语法与 PostgreSQL 完全一致
- 表名列名小写 + 双引号
- 类型映射同 PostgreSQL（int8、int4、timestamp(6) 等）

---

## 九、崖山 建表模板

```sql
CREATE TABLE "BLADE_{TABLE_NAME}" (
  "ID" NUMBER(20,0) NOT NULL,
  "TENANT_ID" NVARCHAR2(12),
  -- 业务字段
  "{COLUMN_NAME}" {yashan_type},
  -- 审计字段
  "CREATE_USER" NUMBER(20,0),
  "CREATE_DEPT" NUMBER(20,0),
  "CREATE_TIME" DATE,
  "UPDATE_USER" NUMBER(20,0),
  "UPDATE_TIME" DATE,
  "STATUS" NUMBER(11,0) DEFAULT 1,
  "IS_DELETED" NUMBER(11,0) DEFAULT 0
)
LOGGING
NOCOMPRESS
PCTFREE 10
INITRANS 1
STORAGE (
  BUFFER_POOL DEFAULT
)
PARALLEL 1
NOCACHE
DISABLE ROW MOVEMENT
;

COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."ID" IS '主键';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."TENANT_ID" IS '租户ID';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."{COLUMN_NAME}" IS '{字段注释}';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_USER" IS '创建人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_DEPT" IS '创建部门';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."CREATE_TIME" IS '创建时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_USER" IS '修改人';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."UPDATE_TIME" IS '修改时间';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."STATUS" IS '状态';
COMMENT ON COLUMN "BLADE_{TABLE_NAME}"."IS_DELETED" IS '是否已删除';
COMMENT ON TABLE "BLADE_{TABLE_NAME}" IS '{表注释}';

ALTER TABLE "BLADE_{TABLE_NAME}" ADD CONSTRAINT "SYS_C00{xxxxx}" PRIMARY KEY ("ID");
```

**崖山特点**：
- 语法与 Oracle 完全一致
- 表名列名大写 + 双引号
- 类型映射同 Oracle（NUMBER、NVARCHAR2、DATE、NCLOB 等）
- 包含 Oracle 存储参数

---

## 十、菜单 SQL 生成

每个新模块需要插入 5 条菜单记录：1 个主菜单 + 4 个操作按钮（新增、修改、删除、查看）。

### MySQL 菜单 SQL

```sql
-- ----------------------------
-- {中文名}菜单数据
-- ----------------------------
INSERT INTO `blade_menu` (`id`, `parent_id`, `code`, `name`, `alias`, `path`, `source`, `sort`, `category`, `action`, `is_open`, `remark`, `is_deleted`)
VALUES ({menuId}, {parentMenuId}, '{modelCode}', '{中文名}', 'menu', '/{module}/{modelCode}', NULL, 1, 1, 0, 1, NULL, 0);

INSERT INTO `blade_menu` (`id`, `parent_id`, `code`, `name`, `alias`, `path`, `source`, `sort`, `category`, `action`, `is_open`, `remark`, `is_deleted`)
VALUES ({addMenuId}, {menuId}, '{modelCode}_add', '新增', 'add', '/{module}/{modelCode}/add', 'plus', 1, 2, 1, 1, NULL, 0);

INSERT INTO `blade_menu` (`id`, `parent_id`, `code`, `name`, `alias`, `path`, `source`, `sort`, `category`, `action`, `is_open`, `remark`, `is_deleted`)
VALUES ({editMenuId}, {menuId}, '{modelCode}_edit', '修改', 'edit', '/{module}/{modelCode}/edit', 'form', 2, 2, 2, 1, NULL, 0);

INSERT INTO `blade_menu` (`id`, `parent_id`, `code`, `name`, `alias`, `path`, `source`, `sort`, `category`, `action`, `is_open`, `remark`, `is_deleted`)
VALUES ({removeMenuId}, {menuId}, '{modelCode}_delete', '删除', 'delete', '/{module}/{modelCode}/delete', 'delete', 3, 2, 3, 1, NULL, 0);

INSERT INTO `blade_menu` (`id`, `parent_id`, `code`, `name`, `alias`, `path`, `source`, `sort`, `category`, `action`, `is_open`, `remark`, `is_deleted`)
VALUES ({viewMenuId}, {menuId}, '{modelCode}_view', '查看', 'view', '/{module}/{modelCode}/view', 'eye-open', 4, 2, 2, 1, NULL, 0);
```

### 菜单字段说明

| 字段 | 说明 | 值 |
|------|------|-----|
| `id` | 主菜单 ID | 生成雪花 ID 或自定义（如 1123598812738675301） |
| `parent_id` | 父菜单 ID | 由用户指定或放在顶级（0） |
| `code` | 权限编码 | 主菜单: `{modelCode}`，按钮: `{modelCode}_{action}` |
| `name` | 显示名称 | 主菜单: `{中文名}`，按钮: 新增/修改/删除/查看 |
| `alias` | 别名 | 主菜单: `menu`，按钮: add/edit/delete/view |
| `path` | 路由路径 | `/{module}/{modelCode}` |
| `source` | 图标 | 按钮: plus/form/delete/eye-open |
| `sort` | 排序 | 按钮从 1 到 4 |
| `category` | 类别 | 1=菜单，2=按钮 |
| `action` | 操作类型 | 0=无，1=新增，2=修改，3=删除 |
| `is_open` | 是否打开 | 1=是 |
| `is_deleted` | 是否删除 | 0=否 |

---

## 附：方言选择速查

| 方言 | 引号风格 | 大小写 | 注释方式 | 事务语法 |
|------|---------|--------|----------|---------|
| MySQL | 反引号 `` ` `` | 小写 | `COMMENT` 内联 | `BEGIN; ... COMMIT;` |
| PostgreSQL | 双引号 `"` | 小写 | `COMMENT ON` | `BEGIN; ... COMMIT;` |
| Oracle | 双引号 `"` | **大写** | `COMMENT ON` | 自动提交/`COMMIT;` |
| SQL Server | 方括号 `[]` | 小写 | `sp_addextendedproperty` | `BEGIN TRANSACTION ... COMMIT GO` |
| 达梦 | 双引号 `"` | **大写** | `COMMENT ON` | 同 Oracle |
| 人大金仓 | 双引号 `"` | 小写 | `COMMENT ON` | 同 PostgreSQL |
| 崖山 | 双引号 `"` | **大写** | `COMMENT ON` | 同 Oracle |

**兼容性分组**：
- **PostgreSQL 系**：PostgreSQL、人大金仓（语法完全一致）
- **Oracle 系**：Oracle、崖山（语法完全一致）
- **接近 Oracle**：达梦（大部分兼容，类型名有差异）
- **独立语法**：MySQL、SQL Server

### 无租户表模式

如果实体不需要 `tenant_id`（BaseEntity 或 Raw 模式），从所有方言模板中移除 `tenant_id` 行即可。其余审计字段保持不变。
