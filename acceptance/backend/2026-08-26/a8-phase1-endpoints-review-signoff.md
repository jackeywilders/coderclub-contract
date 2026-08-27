# A8 阶段一 3 门户端点——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a8-phase1-endpoints-report.md` + `-summary.json`（PR #70 合入交接仓库 main）
> 工作底稿：`designs/backend/2026-08-26/a8-phase1-endpoints-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施分支 `feat/backend-a8-phase1-portal-endpoints`（CoderClub PR #12，head `ceaffe4`，8 commits）经人链核验与独立复验逐项与任务书/决策相符：

- [x] **3 端点完整**：`POST /subject/getSubjectPageBySearch`、`POST /subject/getContributeList`、`POST /auth/user/list-by-identifiers`（C2 方案② 决策的第 3 端点，仅内部跨服务）
- [x] **C4 空串语义**：keyWord 缺失 400 / 空串空页（total=0 不 400）；`SubjectSearchItemVO` `@AutoMapper`（70b146b 修复 ConvertException→500）；LIKE 单列 + distinct 防膨胀
- [x] **C3 分组**：`GROUP BY created_by`（不用 settle_name）+ count 降序 + topN（缺省 10/上限 20）
- [x] **C2 nickName 降级**：Controller 层 Feign 批量取号；失败/缺失/空白 nickName → userName 兜底（200 不 500）
- [x] **独立测试复验**：SubjectContractTest **57/57** + AuthContractTest **12/12**，BUILD SUCCESS（回执称 10/10；`ceaffe4` 补 `@Size(100)`/401 用例 → 覆盖更全）
- [x] **源文档 SHA**：LF `A8C6A460→BA74B152` 与回执 §4 逐字一致；3 路径 + 9 schema 登记完整
- [x] **契约与边界**：`contractSnapshotSha256=8ebcda53` 零变更；未改 `api/` 快照与 `sync-manifest`；未动既有端点/鉴权/错误码/表结构；未新增索引；未跨子表搜索；无真实环境信息（规则 8）

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | 分支 head **`ceaffe4`**（`ceaffe472eaaf3960061068c2db8371d576bba43`，8 commits）；回执 summary 记 `c4e1efb`（中间提交，见备注） |
| 回执提交 SHA | 回执 tip `f435699`（PR #70 合入交接仓库 main）；summary 记 `2903a13` |
| PR 号 | 实施：CoderClub PR #12；回执：交接仓库 PR #70；任务书 PR #69；决策 PR #68 |
| R2 状态 | 回执：已合入交接仓库 main（PR #70）；实施：PR #12 未合入 CoderClub main（open，CI 全绿，合入由用户/后端评审执行） |

## 3. 已知限制处置（回执 §5，标注如下）

| # | 限制 | 处置 |
| --- | --- | --- |
| 1 | groupBy/search SQL 真实执行（Mapper 层 mock） | 云端真实请求验证补充（计划 §7，验收后）；不阻塞签署 |
| 2 | subject Feign 跨服务联调 | 同上（auth 端点与消费者同分支，合入后真实联调） |
| 3 | 401 端到端 | **已解除**：`ceaffe4` 补 401 用例，独立复验 12/12 覆盖 |
| 4 | topN 归一边界 / auth @Size(100) 边界无专属单测 | `@Size(100)` **已解除**（12/12 覆盖）；topN 边界 [仅供参考] 建议验收或云端验证补 |
| 5 | 云端真实请求验证（整体） | 验收后补充（与 A2/A5 先例一致）；签署以独立复验证据为准 |

## 4. 备注（[仅供参考]，不阻塞签署）

- 回执 summary `implementationCommitSha=c4e1efb` 未含最终 tip `ceaffe4`（final review cleanups，12 文件 52+/13-）——引用类小瑕疵（同 A2/A5 先例），建议 B-Impl 或 PM 验收时补正；`ceaffe4` 已在本复核人链核验与独立复验范围内。
- 回执称 AuthContractTest 10/10，独立复验 12/12（`ceaffe4` 补 2 用例）——覆盖更全，非实质差异。

## 5. 关联

- 任务书：`pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69）
- 决策：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68，C1-C4）
- 提案：`proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（PR #67）
- 本签署：`acceptance/backend/2026-08-26/a8-phase1-endpoints-review-signoff.md`

签署：后端评审（B-Review），2026-08-26