# SENSITIVE-WORDS-LIST 敏感词词库 list 端点——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-30
> 任务书：`pm/requirements/2026-08-30/sensitive-words-list-implementation-task.md`（PR #108）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-sensitive-words-list-report.md` + `-summary.json`（PR #109，head `028bcbc`，已合入 main `e3f5462`）
> 提案/决策：`proposals/backend/2026-08-30/sensitive-words-list-proposal.md`（PR #107）· `pm/reviews/2026-08-30/sensitive-words-list-proposal-decision.md`（L1-L3 全确认）
> 实施：CoderClub PR #17（head `90a1e96`，5 commits，**本会话复核通过后已合入 main `8617d9de`，R2 达成**）

## 1. 人链核验：实施提交存在性与一致性

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象 | `git rev-parse 90a1e96…` 成功（本机 worktree 即停于该提交，B-Impl 遗留状态原状未动）；远端 `feat/backend-sensitive-words-list` head 一致 | ✅ |
| CI | PR #17 head `90a1e96`：build-and-test ✅ + sensitive-scan ✅（run 33305070033，GitHub API 逐 job 核实；首推 run 33304005875 经修复波重跑） | ✅ |
| 提交数 | **5 commits**（spec + 实现 + schema/openapi 登记 + 审查修复）——与回执一致 | ✅ |
| summary 一致性 | `implementationCommitSha=90a1e96`、PR #17、`contractSnapshotSha256`、`sourceDoc lfSha256After=24DC8414…` 与回执一致（PR 描述体仍为修复前 `334A34AA`——回执 §6 已给最终值，以回执为准，本底稿独立复核最终值） | ✅ |
| PR #17 合入 | 本会话独立复核（CI 双绿 + 代码级复核 + 独立测试复验全过）后以 merge 方式合入 main（merge `8617d9de`，B-Review 授权合入人身份）——**R2 达成** | ✅ |

## 2. 代码级复核（对照回执 §2，实读源码 @ `90a1e96`）

| 核对项 | 证据 | 结果 |
| --- | --- | --- |
| **实体 +createdTime** | `SensitiveWordsEntity:40` `@Column(value="created_time", onInsertValue="now()")` + `Date createdTime`——flex 自动填充、save 端点零改动；javadoc 登记 A1 来源（用户 2026-08-30 云端 DDL）与存量 NULL 语义 | ✅ |
| **端点** | `SensitiveWordsController:28` 类级 `@SaCheckLogin` + `:59-60` 方法 `@SaCheckRole("admin_user")` + `@PostMapping("/words/list")` 无请求体；`:62-69` 时间格式化 `yyyy-MM-dd HH:mm:ss` + null 防护（消息域先例） | ✅ |
| **排序与只读** | `SensitiveWordsServiceImpl:26-30` `listAllWords()` `orderBy("type", true).orderBy("id", true)` 全量（L2 非分页）；domain `listWords()` 纯透传不触碰 DFA 快照/重建（L3）；`list` 端点不引 WordContext/WordFilter | ✅ |
| **VO 字段面** | `SensitiveWordItemVO {id, words, type, createdTime}`——`words` 复数勘误对齐表列/实体/save DTO；createdTime 串或 null | ✅ |
| **schema 文档（修复确认）** | `doc_jc-club-init.sql` `sensitive_words` 建表语句 `created_time datetime DEFAULT NULL COMMENT '创建时间'` 为**规范列定义、无 AFTER 子句**（`AFTER` 为 ALTER 专属语法，嵌入 CREATE TABLE 重建会 1064——初版缺陷已由 90a1e96 修复，列位置由行序表达，紧跟 type 行） | ✅ |
| **源契约文档** | openapi **75 路径**（`/circle/sensitive/words/list` 存在）、`SensitiveWordItemVO` schema required = `id,words,type`、类型 integer/string 正确；LF SHA = `24dc8414…`（`git show` 独立计算，与回执逐字一致） | ✅ |
| **边界** | 只读不触重建（测试 verifyNoMoreInteractions 锚定）；save/remove 零变化；无运行时 DDL（列已由用户执行）；`api/` 快照与 sync-manifest 未动；无新依赖 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `90a1e96`）

| 命令/动作 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` | **exit 0** |
| 定向测试 circle domain + circle-app-controller | **exit 0，BUILD SUCCESS，零失败** |
| circle domain | **42/42**（SensitiveWordDomainServiceImplTest 5 含只读边界用例） |
| CircleContractTest | **23/23**（20 基线 + 3 新增：200 全量排序/字段面/存量 null 如实 + 新增带时间、401、403） |
| 云端联调 | 本批为管理端只读端点 + 存量/新增时间语义，云端展示语义（null 省略）由前端第二批消费时验证；本会话未重放云端（如实声明） |

## 4. §5.4 规格措辞缺陷核查（B-Impl 报告）

- **根因属实**：`docs/superpowers/specs/2026-08-30-sensitive-words-list-design.md` §1.5 原文要求建表语句"在 `type` 行后补 `` `created_time` … AFTER `type` ``（与已执行 DDL 一致）"——将 ALTER 专属 `AFTER` 子句嵌入 CREATE TABLE（重建会 1064）。**缺陷措辞出自 B-Impl 自身设计规格**（本提案 §3 仅要求"同步列变更，归 B-Impl 批"，未指定逐字嵌入）；B-Impl 忠实执行、最终审查自揪并修复（90a1e96 去除 AFTER），修复正确。
- **口径建议采纳**：后续 schema 文档同步任务明确「**ALTER 语义转写为列定义 + 注释登记实际执行的 ALTER**」——本签署随附此建议交 PM/后续任务书，防同类回归。

## 5. 延后项核查（回执 §5，均为 Minor、不阻塞）

| # | 项 | 复核意见 |
| --- | --- | --- |
| 1 | L2 排序 SQL 无自动化锚定（infra 2 行 orderBy 仅人工保证） | 只读展示顺序、确定性 SQL，风险有界；已由契约测试顺序断言 + 人工核验覆盖，接受延后 |
| 2 | 风格小项（controller 内联 stream、全限定签名等） | 与既有代码风格一致度可接受，延后 |
| 3 | 示例 `createdTime: null` 与 non_null 序列化省略的表述偏差 | 属表述性：OpenAPI description 已注明省略语义，schema 无语义错误；我的提案 §2 示例同款偏差一并登记（前端按空值展示处理已在 PR 描述注明） |

## 6. 复核结论

**通过，签署。** 回执声明（5 提交、SHA `24DC8414`、75 路径、schema 修复、测试数字、边界遵守、A1 无运行时 DDL）与人链核验、代码实读、独立复验逐项一致；§5.4 根因与修复核实正确，口径建议采纳随签署转交。未发现 [必须修复]/[建议修改] 问题。一处流程观察（PR #17 描述体未随最终审查更新 SHA/已知说明，以回执为准）——[仅供参考]。

## 7. 关联

- 签署：`acceptance/backend/2026-08-30/sensitive-words-list-review-signoff.md`
- 提案 PR #107 · 决策 L1-L3 · 任务书 PR #108 · 回执 PR #109 · 实施 CoderClub PR #17（merged `8617d9de`）

---
- 复核角色：后端评审（B-Review），2026-08-30
