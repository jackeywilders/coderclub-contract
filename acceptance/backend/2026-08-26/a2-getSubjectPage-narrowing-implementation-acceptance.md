# PM 验收：A2 getSubjectPage 请求体运行时收窄实施

> 角色：协调 PM
> 验收日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/getSubjectPage-runtime-narrowing-implementation-task.md`（PR #49，已合入 main）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a2-getSubjectPage-narrowing-report.md` + `-summary.json`（PR #50/#51）
> 复核签署：`acceptance/backend/2026-08-26/a2-getSubjectPage-narrowing-review-signoff.md`（PR #52）
> 状态：**验收通过，A2 闭环；快照 description 微同步全链完成**

## 1. 验收依据（规则 9 远程核验）

先 `git fetch`/API 通道核验远端再验收，禁止仅凭本地 worktree 判定：

| 层级 | 判定对象 | 证据 | 结论 |
| --- | --- | --- | --- |
| R1 存在性 | 回执双轨 + 签署文件已在远端可见 | `handoff/backend-to-frontend/2026-08-26/`（report.md + summary.json）、`acceptance/backend/2026-08-26/a2-getSubjectPage-narrowing-review-signoff.md` 均在 `main` 上（`get_file_contents` ref=main 读取成功） | ✅ |
| R2 生效性 | 回执与签署已合入 `main` | PR #50（回执初版）、#51（回执终稿补真实请求验证）、#52（签署）均 closed merged；`main` 顶端 `667ef866`（PR #52 merge commit，github-actions[bot]） | ✅ |
| 四字段 | 实施 SHA / 回执 SHA / PR 号 / R2 状态 | 见 §2 | ✅ |

## 2. 完成通知四字段核验

| 字段 | 值 | 核验 |
| --- | --- | --- |
| 实施提交 SHA | `6b2aedd`（`6b2aeddbb775f5039fa50a3feaa779f05e6fe0ed`，CoderClub `feat/backend-a2-getSubjectPage-narrow`） | summary.json 记录 + B-Review 人链核验一致 |
| 回执提交 SHA | 终稿 `258821e`（PR #51 head）；summary 记录 `4bcf820`（初版，B-Review 工作底稿注明 [仅供参考]） | 签署 §2 注明 |
| PR 号 | 实施：CoderClub PR #8；回执：交接仓库 PR #50/#51；签署：PR #52 | 列表快照 + 详情一致 |
| R2 状态 | 回执/签署：已合入交接仓库 main（`667ef866`）；实施：`6b2aedd` 已合入 CoderClub main（merge `0098365`，签署时点 open、验收时点已合入，本地 `git log --graph` 复核） | ✅ |

## 3. 验收标准逐项核对（对照任务书）

| 任务书要求 | 证据 | 结论 |
| --- | --- | --- |
| controller 请求体收窄为 `SubjectPageQueryDTO` + 显式映射 6 字段（pageNo/pageSize/subjectDifficult/categoryId/labelId/subjectType） | 回执 §2.1/§2.2；B-Review 代码级复核签署 | ✅ |
| 保留 `@Validated(Groups.PageQuery)` 分组 | 回执 §2.1；B-Review 复核 | ✅ |
| `SubjectContractTest` 51/51 回归 + 补「多余字段忽略不 400」用例 | `mvn test` BUILD SUCCESS；`Tests run: 52, Failures: 0, Errors: 0`（51 基线 + 1 新增，用例名 `getSubjectPage_shouldIgnoreExtraFields_andNotReturn400`） | ✅ |
| 行为保持硬条件：多余字段仍静默忽略、不得 400 | mock 层用例（HTTP 200 非 400 + `@AutoMapper` 透传断言）+ 真实请求验证 B 组（6 字段 + 7 多余字段 → 200，结果与 A 组逐位一致） | ✅ |
| 真实请求验证（云端中间件环境） | 回执 §4：无登录态 401；A 组 6 字段筛选 total=28→6；B 组多余字段不 400 | ✅（`-summary.json` verificationResult `passed`） |
| 后端源文档 `SubjectPageQueryDTO` description 更新（A2 决策附带条件 2，已批准） | 源 `docs/api/coderclub-openapi.json` description「getSubjectPage 请求体即本 DTO，6 字段全部参与筛选。」；LF 字节态 SHA before `05933BEA` / after `A8C6A460`，与回执 §5 一致 | ✅ |
| 禁止：改交接仓库 `api/` 快照与 `sync-manifest` | B-Impl 声明（回执 §7）+ B-Review 边界检查（签署 §1）；验收时点确认快照仍为 `0DAE8D3A`（由 PM 验收后微同步，见 §4） | ✅ |

## 4. 快照 description 微同步（决策附带条件 2，P1/P3 模式）

- **同步内容**：`api/coderclub-openapi.json` `SubjectPageQueryDTO.description`：「分页查询请求体。实际绑定 SubjectInfoDTO，此处仅展示常用过滤字段。」→「getSubjectPage 请求体即本 DTO，6 字段全部参与筛选。」（与源一致，一次导入，无其他字段/结构/路径变更）
- **SHA 全链**：

| 项 | 同步前 | 同步后 |
| --- | --- | --- |
| 源提交（sourceCommit） | `f964f88` | `6b2aedd`（A2 实施提交，含 description 更新；已合入 CoderClub main merge `0098365`） |
| 源 SHA-256（LF 口径） | `05933BEA…` | `A8C6A4607EA21FBFE932D7CDB6464CF77595846F133A0DC42AD8C56291A6DD26` |
| 快照提交（snapshotCommit） | `7235e18` | 本批次快照更新提交（见 PR 合入记录） |
| 快照 SHA-256 | `0DAE8D3A753EC86048601813950F2BE59A2C03D2386C5697A44970B15A988D61` | `8EBCDA5362BC0F882E7C9880FA08919ECD0A8604EFF9F38A0B9533DF639231BC` |
| 语义差异数 | 17 | 18（+1 A2 description 微同步） |

- `status/pm.json` 与 `status/sync-manifest.json` 的 `contractSnapshot` 全链同步更新（同批提交）。

## 5. 验收结论与后续

- **验收通过**：A2（getSubjectPage 运行时收窄，案 B/C）实施闭环。
- **state 推进**：`gate3-a3-accepted` → `gate3-a2-impl-accepted`（状态文件同批更新；对照 m4AcceptanceReports 白名单一致，无 in-progress 冲突）。
- **遗留**：A5（`doc_jc-club-init.sql` 个人数据脱敏）、A1（DB ALTER，需 MySQL 凭据）、A7（前端 worktrees 清理，需授权）、A8/A9（发布门禁，需用户授权）——均不在本期范围。

## 6. 关联

- 决策：`pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`（PR #41）
- 提案：`proposals/backend/2026-08-26/getSubjectPage-request-schema-alignment-proposal.md`（PR #40）
- 任务书：`pm/requirements/2026-08-26/getSubjectPage-runtime-narrowing-implementation-task.md`（PR #49）
- 签署：`acceptance/backend/2026-08-26/a2-getSubjectPage-narrowing-review-signoff.md`（PR #52）
- 本验收：`acceptance/backend/2026-08-26/a2-getSubjectPage-narrowing-implementation-acceptance.md`

验收：协调 PM，2026-08-26