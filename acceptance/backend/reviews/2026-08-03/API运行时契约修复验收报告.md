# CoderClub API 运行时契约修复验收报告

## 1. 验收结论

### 1.1 代码与运行时验收

**代码实现验收通过。** 本次计划涉及的统一响应字段、空数组序列化和 Subject 分类映射均已落地，受影响模块测试和全量安装构建通过。

### 1.2 文档验收

**API 文档和前端接入文档需小范围修订后再作为最终交付版。** 当前接口路径、请求字段和主要响应模型没有发现需要调整的地方，但文档对“无数据”的描述不够精确：部分位置将所有空结果都描述为 `data: null`，与实际列表接口返回 `data: []`、分页接口返回 `data.list: []` 的行为不一致。

> **2026-08-03 修订**：§4.1/§4.2 文档问题已修复（commit `f6a776f`，详见第 8 节整改核验记录），本小节验收结论更新为**通过**。

## 2. 审查范围

- `ResponseResult` 空数据和空数组序列化实现。
- Auth、Subject 的 Jackson 序列化配置。
- Subject 分类 Entity/BO 显式组装和分类树行为。
- Common、Auth、Subject 受影响模块测试。
- OpenAPI 文档和前端接入手册与运行时契约的一致性。
- M3 联调记录中的空数组运行时证据和已记录遗留问题。

## 3. 实施内容核验

| 核验项 | 实现位置 | 结果 |
| --- | --- | --- |
| 无数据响应保留 `data: null` | `coder-club-common/src/main/java/com/jackey/common/entity/res/ResponseResult.java` | 通过 |
| Auth 空数组输出 `[]` | `coder-club-auth/coder-club-auth-starter/src/main/resources/application.yaml` | 通过 |
| Subject 空数组输出 `[]` | `coder-club-subject/coder-club-subject-starter/src/main/resources/application.yaml` | 通过 |
| 分类 Entity/BO 显式转换 | `SubjectCategoryAssembler` | 通过 |
| 分类 DomainService 统一使用组装器 | `SubjectCategoryDomainServiceImpl` | 通过 |
| 分类树、条件查询和反向写入回归测试 | `SubjectContractTest` | 通过 |

`ResponseResult.data` 使用属性级 `@JsonInclude(JsonInclude.Include.ALWAYS)`，没有扩大 Auth、Subject 的全局 `non_null` 范围。Auth 和 Subject 的 `write-empty-json-arrays` 已设置为 `true`，与 OSS 默认行为保持一致。

## 4. 分级问题

### 4.1 [必须修复] “无数据”语义与实际运行时不一致

**位置：**

- `docs/api/coderclub-openapi.json` 顶层 description。
- `docs/frontend/handoff/2026-08-03-frontend-integration-guide.md` 第 1 节统一响应说明。

当前文档使用“无数据时 `data` 为 `null`”的概括性描述，但实际运行时存在三种明确情况：

| 场景 | 实际响应 |
| --- | --- |
| 无业务载荷的成功或失败响应 | `data: null` |
| 数组接口没有匹配结果 | `data: []` |
| 分页接口没有匹配结果 | `data: { "list": [], ... }` |

前端手册的标签接口章节已经说明 `data=[]` 是正常空结果，但与第 1 节总则形成了语义不一致。前端若只按 `data === null` 处理空状态，可能错误处理列表接口空结果。

**建议：** 将两份文档统一表述为：

```text
无业务载荷时 data 为 null；数组接口无结果时 data 为 []；分页接口无结果时 data.list 为 []。
```

### 4.2 [建议修改] OpenAPI 分页内部字段未标记为必需

**位置：** `docs/api/coderclub-openapi.json` 中的 `PageResultSubjectInfo` 和 `PageResultAuthUser`。

两个分页模型声明了 `pageNo`、`pageSize`、`total`、`totalPages` 和 `list` 属性，但没有声明内部 `required` 字段。实际 `PageResult` 默认初始化 `list` 为空列表，分页响应应稳定提供 `data.list`。

**建议：** 为两个分页模型补充：

```json
"required": ["pageNo", "pageSize", "total", "totalPages", "list"]
```

本项不需要修改接口路径、请求参数或主要字段类型。

## 5. 验证记录

### 5.1 自动化测试

以下命令均以 `coder-club-dependencies/pom.xml` 作为 Maven 聚合入口，并使用 artifactId 选择器执行：

| 模块 | 命令结果 | 测试结果 |
| --- | --- | --- |
| Common | `BUILD SUCCESS` | 21/21，通过 |
| Auth Controller | `BUILD SUCCESS` | 5/5，通过 |
| Subject Controller | `BUILD SUCCESS` | 43/43，通过 |
| 全量安装 | `mvn -f coder-club-dependencies/pom.xml install -DskipTests -q` | 通过 |

测试汇总：**69/69 通过，Failures 0，Errors 0，Skipped 0。**

### 5.2 运行时联调证据

M3 联调记录已验证以下响应：

- 注册成功响应包含 `data: null`。
- 空分类查询响应包含 `data: []`。
- 空分页响应包含 `data.list: []`。
- 三种响应均保留 `success`、`code`、`message`、`data` 四个顶层字段。

证据位置：`docs/backend/milestones/M3/reports/2026-08-02-M3联调记录.md` 附录 B。

### 5.3 文档与工作树检查

| 检查项 | 结果 |
| --- | --- |
| OpenAPI JSON 解析 | 通过，OpenAPI 3.0.3 |
| OpenAPI 路径数量 | 45 |
| 要求顶层 `data` 字段的响应模型 | 14 个 |
| `git diff --check` | 通过 |
| 工作树状态 | 干净 |

## 6. 遗留风险与移交项

### 6.1 [建议修改] 分页 `total` 与 `list` 过滤口径不一致

联调记录发现，`getSubjectPage` 使用特定过滤条件时可能返回 `list: []`，但 `total` 仍为未过滤前的数量。例如联调中出现 `list: []`、`total: 23` 的响应。

该问题不影响本次空数组序列化修复，但会影响前端分页器显示，应在 M4 评审 `SubjectInfoServiceImpl.countByCondition` 与分页查询条件的一致性。不能通过修改文档掩盖该问题。

### 6.2 非阻塞构建警告

验证过程中出现 Maven Compiler Plugin 未显式声明版本、Mockito 动态加载 Java Agent、Subject 测试类路径存在多个 SLF4J Provider 等警告。本次未导致构建或测试失败，建议后续纳入构建质量治理。

## 7. 最终裁决

| 项目 | 裁决 |
| --- | --- |
| API 运行时契约修复 | **通过** |
| Subject 分类映射修复 | **通过** |
| 自动化测试和全量构建 | **通过** |
| OpenAPI 结构 | **通过，无需改接口模型类型** |
| OpenAPI 描述文字 | ✅ 已修订（2026-08-03，统一三态语义） |
| 前端接入手册 | ✅ 已修订（2026-08-03，统一三态语义） |

**最终建议：** 代码与文档均已达交付标准。§4.1/§4.2 文档问题已于 2026-08-03 修订（见第 8 节整改核验记录）；§6.1 分页 total 与 list 过滤口径不一致属代码缺陷，按开发方决定移交 M4 评审 `SubjectInfoServiceImpl.countByCondition`。

## 8. 整改核验记录（2026-08-03）

> 依据本报告 §7 最终建议，开发方完成文档整改；代码侧问题按开发方决定移交 M4。

| 报告问题 | 状态 | 说明 |
|---|---|---|
| §4.1 [必须修复] “无数据”语义表述不精确 | ✅ 已修复 | OpenAPI 顶层 description 与前端手册 §1 统一为三态表述：无业务载荷时 data 为 null、数组接口无结果时 data 为 []、分页接口无结果时 data.list 为 [] |
| §4.2 [建议修改] 分页模型缺 required | ✅ 已修复 | `PageResultSubjectInfo`、`PageResultAuthUser` 补 `required: [pageNo, pageSize, total, totalPages, list]` |
| §6.1 [建议修改] 分页 total 与 list 过滤口径不一致 | ⏭ 移交 M4 | 根因：`countByCondition` 的 subjectType/subjectDifficult 条件落在 LEFT JOIN ON 子句、未实际过滤；M4 评审 `SubjectInfoServiceImpl.countByCondition` |

修复提交：`f6a776f`（docs: 统一空数据语义表述并补分页模型必填字段）。OpenAPI JSON 解析通过、两分页模型 required 已生效、手册三态表述与运行时一致。
