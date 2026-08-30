# A8 阶段三 circle 社区域实现（A8-P3-BE）——PM 验收

> 验收角色：协调 PM
> 验收日期：2026-08-30
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-circle-domain-report.md` + `backend-a8p3-circle-domain-summary.json`（PR #97，head `101b900`，签署已并 PR #100）
> 复核签署：`acceptance/backend/2026-08-30/a8p3-circle-domain-review-signoff.md`（PR #100，merged，MCP 核验）
> 状态：**验收通过**

## 1. 验收结论

✅ **A8-P3-BE 验收通过。** 实施 `d9eb64f`（18 commits = 3 携带 + 15 实现）经 B-Review 复核签署（PR #100）与 PM 独立核验，与提案（PR #94）及决策（X1-X6/D0）相符；契约快照全链同步随本验收执行（63→74 路径）。

## 2. 规则 9 核验链（四字段）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `d9eb64f`（`d9eb64fb51c7ee5f22c947b4ee77c34574d38a1c`，18 commits） |
| 回执提交 SHA | `101b900`（PR #97 head；回执 PR 合入流程按分支保护独立继续） |
| PR 号 | CoderClub PR #15——**merged（merge `583b4bb`，2026-08-29T19:27:07Z）** |
| R2 状态 | ✅ 实施已合入 CoderClub main（`583b4bb` 为 main 当前头，MCP list_commits 核验）；签署 PR #100 已合入交接仓库 main |

签署勘误采信：18 commits（3 携带 + 15 实现）、评论域单测 10（总数 33 正确）。

## 3. PM 独立复核（非签署转录）

1. **源契约实测**：`docs/api/coderclub-openapi.json` LF SHA-256 = `736F65886FC60E758AF6AB2F1C306BF47259CBEFACF69AC94FA032C567753225`（与回执/签署声称逐字一致）；74 路径 / 117 schemas / 74 操作实测。
2. **全量 diff 分类**（源 74 vs 快照 2583B906）：新增 11 circle 端点（圈子树 1 / 动态 3 / 评论 3 / 消息 2 / 敏感词管理 2）+ 21 schemas；X1/X2 语义登记（端点 description + `UserIdentifierQueryDTO.identifiers.description` + `SubjectPageQueryDTO.primaryCategoryId` 增字段）；servers +practice 条目（localhost 示例端口）；tags +练习/题目内部/圈子；8 处 auth 例子脱敏点延续；快照侧 `info.description` 为 43 路径时代文案（A8-P1/P2 两代欠账）。
3. **敏感扫描（新增内容）**：仅 `cdn.example.com` 保留示例域名（与既有快照 26 处口径一致）与"未登录或Token已过期"401 通用文案；无真实环境信息、无真实凭据值。
4. **PM 增值发现（历史脱敏遗漏补齐）**：`TokenInfo.tokenValue.example` 与 `LoginResponse.data.token.example` 两处 schema 例子为 32 位 hex token 样式值（旧快照 2583B906 同在，历史登记脱敏未覆盖），本轮一并补脱敏 `<token>`（口径与既有 8 处一致）。
5. **快照全链同步执行**：`2583B906 → DAAEECB7`（74 路径 / 117 schemas / LF）；同步后与源 diff 复核 = 11 项（10 脱敏 + 1 description 治理修正）；语义差异计数按实测 re-based：38 → 11（依据见 §4）。

## 4. 快照同步登记

| 项 | before | after |
| --- | --- | --- |
| sourceCommit | `a57f6b8a`（A8-P2 实施） | `d9eb64f`（A8-P3 实施，经 CoderClub PR #15 → main `583b4bb`） |
| sourceSha256（LF） | `9EC37C66…` | `736F6588…` |
| snapshotSha256 | `2583B906…` | `DAAEECB79841F0EAC76E5031C1E34EC75C46BAA27151DEF99A26A5291F7B8170` |
| pathCount | 63 | 74 |
| schemaCount | 96 | 117 |
| semanticDifferenceCount | 38 | 11（re-based 实测口径） |

**re-based 说明**：先前 38 项为多轮累计登记口径（14 脱敏值 + 3 P1/P3 + 1 A2 description + 3 A8-P1 端点 + 17 A8-P2 端点）。本轮全链同步把全部既有语义增补融入快照；对当前（源, 快照）对做全量 diff 复算，实际差异 = 10 处脱敏占位符（8 处 auth 路径例子 + 2 处 schema 例子，后者为本轮补齐的历史遗漏，见 §3.4）+ 1 项 `info.description` 治理修正 = **11**。该口径以实测全 diff 为准，可随时复算。

**info.description 授权项执行**（B-Impl 请求项，PM 已授权）：快照侧更新为「覆盖认证、用户、角色、权限、分类、标签、题目、文件存储、练习、圈子 10 大模块共 74 个路径 74 个操作（A8-P2 登记 practice 13 端点 + subject internal 4 端点，A8-P3 登记 circle 圈子 11 端点；internal 端点仅内部 Feign 消费，不向 C 端门户宣传）」+ 既有统一响应段与 A8-P1 鉴权墙段——同时补齐快照侧两代欠账（原 43 路径文案）。源侧头部仍为 63 措辞（上轮任务书冻结所致），配套实现任务书已授权源侧同步修正为同款文案，届时该项差异消除（11→10）。

## 5. 目录偏差追认

回执落盘目录 `handoff/backend-to-frontend/2026-08-30/`（任务书原指定 `2026-08-29/`）——按治理规则 6「日期目录以创建日期（Asia/Shanghai）为准」**追认**（B-Review 08-29 同模式先例）。

## 6. openFindings 处置

| finding | 处置 |
| --- | --- |
| `x1-consumer-key-mismatch`（**新登记**） | open——C1：X1 查询层已就位但响应 VO 无 `id`，消费方按 userName 建键，数字标识昵称解析降级标识串（云端实测 `nickName="1"/"9"`）。随配套提案①（PR #101，已确认）实现验收关闭，practice 排行昵称修复为验收口径 |
| `notrole-mapping-gap`（**新登记**） | open——subject/practice GlobalExceptionHandler 缺 `NotRoleException` 映射（sa-token 1.46.0 兄弟类语义，角色注解失败将 500）。随配套提案②（PR #101，已确认）实现验收关闭 |
| `categoryId-primary-filter-semantics` | **closed（2026-08-30）**——A8-P1 提出的大类过滤语义诉求由 A8-P3 X2 `primaryCategoryId` 可选过滤闭环（已实现、云端联调验证、快照登记） |
| `auth-role-check-gap` | open 保持——提案② N3 边界知悉，auth SaInterceptor 另案 |
| `practice-detail-unique-index` / `pageinfo-duplication` | open 保持——随后续提案评估 |

## 7. 观察项知悉（承接签署 §3，不阻塞验收）

云端 403 未实测（单一 admin 测试账号；契约测试真实拦截链覆盖）；敏感词 remove→重建云端 e2e 未测（管理端无 list 端点；单测覆盖，X6 另案评估）；`share_message.created_by` 落 null（蓝本同款，`from_id` 承载行为主体）；Docker 实机构建待部署环节（容器注意 `TZ=Asia/Shanghai`）；后端仓库本机 worktree detached @ `d9eb64f`（由用户酌情切回 main）。

## 8. 后续

1. 配套两提案已确认：`pm/reviews/2026-08-30/phase3-companion-proposals-decision.md`；B-Impl 小批次任务书已派发：`pm/requirements/2026-08-30/phase3-companion-implementation-task.md`。
2. 前端阶段三（F-Impl 鸡圈页）任务书具备派发条件（快照 74 已就绪），下轮派发。
3. 阶段三前端回执签署并验收后推进 state `gate3-a8-phase3-*`（本验收按先例不推进 state）。

---

验收人：协调 PM，2026-08-30
