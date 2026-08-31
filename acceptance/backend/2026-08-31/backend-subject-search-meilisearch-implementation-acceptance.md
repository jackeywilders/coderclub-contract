# subject 搜索升级 Meilisearch（SUBJECT-SEARCH-MEILISEARCH）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-31
> 回执：`handoff/backend-to-frontend/2026-08-31/backend-subject-search-meilisearch-report.md` + `-summary.json`（PR #153，`receiptCommitSha=2be6316` + 修正 `c06fc70`，已合入 main）
> 复核签署：`acceptance/backend/2026-08-31/backend-subject-search-meilisearch-review-signoff.md` + 工作底稿 `designs/backend/2026-08-31/backend-subject-search-meilisearch-review-workpaper.md`（PR #154，merged，MCP 核验）
> 状态：**验收通过**

## 1. 验收结论

✅ **SUBJECT-SEARCH-MEILISEARCH 验收通过。** 实施 `73b98ea`（9 commits，经 CoderClub PR #22 合入 main `dc0dd284`）经 B-Review 复核签署（PR #154）与 PM 独立核验，与任务书 `pm/requirements/2026-08-31/subject-search-meilisearch-task.md`（grill 共识：Meilisearch 引入、既有端点改造前端无感、写后同步 + 全量重建、ES 移除）相符——Meili 全文检索 `subject_pool`（扩展字段保全既有 4 筛选）、`getSubjectPageBySearch` 契约不变 + 降级 LIKE、三写钩子 + admin 重建幂等。**本批快照零变更**（openapi 无端点登记）；`/subject/search/admin/rebuild` 端点登记按规格 S5.3 裁决挂起至 interview 批次微同步一并执行。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `73b98ea`（`73b98ea7458358c79aaa86db97b7f36a8d5c6ee3`，9 commits：spec + plan + S1-S4 + 3 审查修复波） |
| 合并提交 SHA | `dc0dd284`（CoderClub PR #22 merge，2026-08-31T20:40:23Z，合并人 JackeyWilder） |
| 回执提交 SHA | `2be6316`（PR #153，merge `5ce79b1`；receiptCommitSha 修正 `c06fc70`） |
| PR 号 | CoderClub #22（merged `dc0dd284`）；交接仓库回执 #153、签署 #154（均 merged） |
| R2 状态 | ✅ 双达成：实施合入 CoderClub main（`dc0dd284`）；回执/签署均合入交接仓库 main |
| CI | run `33424822450` 双绿：build-and-test（job 99595739795 success）+ sensitive-scan（job 99595739380 success） |

## 3. PM 独立复核（非签署转录）

1. **实施 R2 实测（远端 main）**：CoderClub PR #22 已合入 main（merge `dc0dd284`，合并人 JackeyWilder，20:40:23Z）；CI 双绿逐 job 核验（run 33424822450）；PR 文件清单 16 files 不含 `docs/api/coderclub-openapi.json`——openapi 零变更确认。
2. **签署链实测**：交接仓库 PR #154 已合入 main（merge `f49372f`，20:41:57Z）；signoff + workpaper 双文件落库；回执双轨（report + summary，`receiptCommitSha=2be6316`）已在 main（PR #153 merge `5ce79b1`）。
3. **源契约实测（远端 main）**：`docs/api/coderclub-openapi.json` LF SHA-256 = `57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4`（复算一致，与 D2 验收后源一致）；75 路径 / 119 schemas——**本批源文档零变更**（回执登记 `26AEC009` 系基线 `86a09e7` 过期值，B-Review 已采纳 PM 注记，无需 B-Impl 补正）。
4. **快照处理（零变更）**：快照保持 `ADCCD073`（75 路径 / 119 schemas / LF 无尾换行 2 空格缩进），与源 diff = **12 项**（10 脱敏 + 2 治理修正，构成不变）；`/subject/search/admin/rebuild` 端点登记**挂起**至 interview 批次微同步（规格 S5.3 裁决 + 签署 §5「路径数随 interview 端点一并」）。
5. **敏感扫描**：快照未变沿用 ADCCD073 既有合规状态；回执/签署全文无真实 IP/凭据（规则 8 占位合规）。

## 4. 快照微同步登记（本批零变更 + 挂起项）

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `f6c23a04e96`（D2 实施） | `f6c23a04e96`（本批源文档零变更；backendCommit 追踪 `dc0dd284`） |
| sourceSha256（LF） | `57C2D6EE…` | `57C2D6EE…`（不变） |
| snapshotSha256 | `ADCCD073…` | `ADCCD073…`（不变） |
| pathCount / operationCount | 75 / 75 | **75 / 75**（不变） |
| semanticDifferenceCount | 12 | **12**（构成不变） |
| 挂起登记 | — | `/subject/search/admin/rebuild` 端点登记：interview 批次微同步一并执行（规格 S5.3） |

## 5. 延后项/观察项登记（承接签署 §4，均不阻塞）

| # | 项 | 处置 |
| --- | --- | --- |
| 1 | 全量重建 N+1 联查（brief/mapping/label 逐实体） | 延后批量优化，接受 |
| 2 | `total` 为 Meili 估计值（maxTotalHits 1000 封顶） | 当前量级不触顶，登记，接受 |
| 3 | 排序语义变化（Meili 相关度 vs 原 LIKE 无序） | 行为改进，规格/回执/签署登记，接受 |
| 4 | rebuild 端点未登记 openapi | 规格 S5.3：PM interview 批次微同步一并，接受 |
| 5 | 命中数/实得行数理论漂移 | 量级内无影响，接受 |
| 6 | 写钩子不 ensureIndex | 当前版本可工作，懒 ensureIndex 延后，接受 |
| 7 | add 钩子事务内写 Meili（幽灵文档低概率） | 重建兜底可清，知晓登记，接受 |
| 8 | delete 钩子桩 doc 内容不完整（仅 id+isDeleted=1） | filter 恒 is_deleted=0 不命中、功能正确，接受 |

## 6. 后续

1. **前端搜索页直连 Meili 语义**：无契约变化，前端零改动；搜索相关度/排序以 Meili 表现为准（行为改进登记）。
2. **Meilisearch 部署验证（A1）**：用户已部署 Meilisearch（服务器 33.8MB 容器），subject 服务经 Nacos 占位配置对接；重建/搜索运行时验证归部署验收环节。
3. **快照微同步批次**：interview 端点（75→83）合批时一并登记 rebuild 端点。
4. 同批其余两线（redis-integration / r2-backup）B-Impl 推进中，回执到位后走签署 → 验收。

---

验收人：协调 PM，2026-08-31
