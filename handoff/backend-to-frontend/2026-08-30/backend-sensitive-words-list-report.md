# 回执：敏感词词库 list 端点实现（B-Impl 小批次）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-30（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-30/sensitive-words-list-implementation-task.md`（PR #108 已合入 main）
> **提案：** `proposals/backend/2026-08-30/sensitive-words-list-proposal.md`（PR #107，R2 main）；PM 决策 L1-L3 全确认
> **设计：** 后端仓库 `docs/superpowers/specs/2026-08-30-sensitive-words-list-design.md`（spec+计划合一，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-sensitive-words-list`（基于 `b15a735` = 配套批 PR #16 合入后 main） |
| 实现头 | `90a1e96`（5 提交：spec + 实现 + schema 文档 + openapi 登记 + 审查修复波） |
| PR | **#17**（feat/backend-sensitive-words-list → main） |
| CI | `build-and-test` ✅ + `sensitive-scan` ✅（run 33304005875 首推；修复波重跑 33305070033 双绿） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 §1 六项 + 提案 L1-L3）

1. **实体** ✅：`SensitiveWordsEntity` 增 `createdTime`（`@Column(value="created_time", onInsertValue="now()")`——flex 既有自动填充，save 端点零改动；存量行 DB NULL；不补 created_by，提案 §3 另案）。
2. **端点** ✅：`POST /circle/sensitive/words/list`——类级 `@SaCheckLogin` + 方法 `@SaCheckRole("admin_user")`（403 由既有 NotRoleException 映射承接）；无请求体；返回 `ResponseResult<List<SensitiveWordItemVO>>`；infra `listAllWords()` 排序 `type ASC, id ASC` 全量（L2 非分页）；**只读**：domain `listWords()` 纯透传，不触碰 DFA 快照/重建（L3，测试硬断言锚定）。
3. **VO** ✅：`SensitiveWordItemVO {id: Long, words: String, type: Integer, createdTime: String}`——`words` 复数（勘误对齐表列/实体/save DTO）；createdTime "yyyy-MM-dd HH:mm:ss" 串或 null（circle 消息域时间格式先例；non_null 序列化下 null 字段省略）。
4. **契约测试** ✅：CircleContractTest +3——200 全量（排序 type ASC+id ASC 顺序断言 + 字段面 + **存量行 createdTime null 如实（doesNotExist 断言）+ 新增词带时间（格式化串断言）**）/ 401 / 403（真实 SaInterceptor 拦截链）；domain `listWords_直查infra_只读不触重建`（连调两次 + `verifyNoMoreInteractions` 只读边界）。
5. **schema 文档** ✅：`doc_jc-club-init.sql` sensitive_words 建表语句补 `created_time datetime DEFAULT NULL COMMENT '创建时间'`（与用户 2026-08-30 云端已执行 DDL 对齐，A1 模式）。**审查修复**：初版误嵌 ALTER 专属 `AFTER \`type\`` 子句（CREATE TABLE 内非法，复放重建 1064）——已删除，列位置语义由行序表达（紧跟 type 行）。
6. **源契约文档** ✅：74→**75** 路径 + `SensitiveWordItemVO` schema（required = id/words/type）+ `ResponseResultSensitiveWordItemList` wrapper + 401/403 引用既有 `CircleErrorResponse`；**LF SHA before/after：`BF59FECD7DA3A97BBC86CA589AA2D0E21CCD450444A63CE82B8AD040E49382B4` → `24DC841402BB5E063758A4156FC3AAF8D84609845BC218D92D0DC8FE6C7DD82A`**（修复后最终值；中间值 334A34AA 为审查修复前——提交正文含完整链）；`info.description` 的"74 个路径"计数措辞随 PM 快照微同步（74→75）一并修正。

## 3. 测试证据

- 全仓 `mvn install -DskipTests` + `mvn test` 绿（15 测试模块零失败）；circle domain 42/42、CircleContractTest 23/23（20+3）；CI 双绿（run 33305070033，head `90a1e96`）。
- 既有 save/remove 语义与 DFA 方案 A′ 快照链路零触碰（list 纯只读，verifyNoMoreInteractions 锚定）。
- 审查链：spec 自检 → 内联 TDD（RED→GREEN→commit）→ 全分支最终审查（1 Important + 2 Minor 修复波，定向复审 **3/3 ADDRESSED**）。

## 4. 边界遵守声明（任务书 §3）

- 只读端点：不触碰词库缓存/DFA 重建；save/remove 既有语义与契约零变化；不补 created_by 列（另案专项）。
- 未动 `api/` 快照与 `status/sync-manifest.json`；无运行时 DDL（created_time 列用户已云端执行，本批仅 schema 文档同步）。
- 无新依赖；示例语义化（规则 8）；Conventional Commits。

## 5. 已知限制与延后项

1. **L2 排序 SQL 无自动化锚定**（审查 Minor）：infra 的 2 行 orderBy 仅人工 review 保证（契约/domain 测试 mock 各自层）——只读展示顺序、确定性 SQL，风险有界；后续可把 wrapper 构造提为可测单元或补 mapper 层测试（延后登记）。
2. **风格小项**（审查 Minor）：controller 内联 `java.util.stream.Collectors.toList()`、domain 接口全限定签名、契约测试全限定 post 调用（可加重载 helper）——延后。
3. **openapi 200 示例表述性偏差**（审查 Minor）：示例含 `"createdTime": null`，实际 non_null 序列化下省略（description 已正确注明）——表述性，不涉 schema 语义。
4. **规格措辞缺陷报告（交 PM/B-Review）**：本批规格 §1.5「与已执行 DDL 逐字一致」措辞导致 ALTER 片段误嵌建表语句（实现忠实执行了有缺陷的规格，审查发现后修复）——建议后续 schema 文档同步任务书/规格明确「ALTER 语义转写为列定义 + 注释登记实际执行的 ALTER」口径。
5. `createdTime: null` 在序列化下省略字段（前端管理页按空值展示处理，PR 描述已注明）。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → 快照微同步 74→**75** → F-Impl 第二批（管理端敏感词管理页）衔接。
2. 合入提醒：PR #17 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。

---
- 回执角色：后端实现（B-Impl），2026-08-30
