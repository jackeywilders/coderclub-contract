# PM 验收：前端门户化阶段一（A8-P1，T1-T6）——A8 阶段一收尾

> 角色：协调 PM
> 验收日期：2026-08-27
> 任务书：`pm/requirements/2026-08-27/frontend-portalization-task.md`（PR #73）
> 回执：`handoff/frontend-to-backend/2026-08-27/frontend-portalization-report.md` + `-summary.json`（PR #74/#75）
> 复核签署：`acceptance/frontend/2026-08-27/frontend-portalization-acceptance.md`（F-Review，PR #76）
> 状态：**验收通过，A8 阶段一（门户化）闭环；完工**

## 1. 验收依据（规则 9 远程核验）

| 层级 | 判定对象 | 证据 | 结论 |
| --- | --- | --- | --- |
| R1 | 回执双轨 + 签署文件远端可见 | `handoff/frontend-to-backend/2026-08-27/frontend-portalization-*`、`acceptance/frontend/2026-08-27/frontend-portalization-acceptance.md` 均在 main | ✅ |
| R2 | 回执（PR #74/#75）、签署（PR #76）合入交接 main（`265991e`）；实施前端 PR #12 merge `cf9d460b`（API 通道核验） | ✅ |
| 四字段 | 实施 `6909558`（8 commits a413b19→6909558）、回执 `60d7f5bb`、PR #12/#74/#75/#76、R2 已合入 | summary + 签署一致 | ✅ |

## 2. 验收标准逐项核对（对照任务书 §5）

| 要求 | 证据 | 结论 |
| --- | --- | --- |
| T1-T5 门户化落地 | 签署 §3 逐项：PortalLayout（鸡翅CLUB Header/4 菜单占位/搜索框/用户菜单）、路由重构（`/` 三栏、answer 移入门户、search 新增、login 门户化；`/subject/browse` 移除；管理布局全保留）、三栏首页（分类联动零新增 + 竞态令牌）、刷题同页翻页（query 上下文，刷新可恢复，边界禁用）、搜索页（空串不发请求 + 空态区分）、登录扫码占位（`/wx-login` 保留） | ✅ |
| T6 userinfo 对齐 | 5 文件 `userName`/`nickName` 落地，`\busername\b`/`\bnickname\b` 精确扫描残留 0（case-insensitive 误报已复核排除） | ✅ |
| 基线 46 端点 | `api-docs-baseline.json` `specSha256=4bfb3c72a445…`、`endpointCount=46`（新 3 端点均在）；`api:check` 通过 | ✅ |
| 验证 | 本机 build/test(10/10)/api:check/lint 全绿 + 前端 CI（PR #12 check）SUCCESS（run 33038587769） | ✅ |
| 回执双轨 + 四字段 | 双轨落 `handoff/frontend-to-backend/2026-08-27/`（PR #74/#75）；通知字段齐 | ✅ |
| 禁止项 | 未改后端/交接仓库 `api/` 快照与 `sync-manifest`（4bfb3c72 零变更）；未引新依赖；未动答题判分行为 | ✅ |

## 3. 已知限制处置（签署 §5，不阻塞）

| # | 项 | 处置 |
| --- | --- | --- |
| 1 | **categoryId 一级过滤语义待确认** | 登记为另案（PM 与后端确认语义：当前前端取二级等值过滤，保守合理；若需一级递归过滤后端另提案）；不阻塞本验收 |
| 2 | 组件级单测受零依赖约束未引 vitest | 接受；以类型检查 + 任务级审查 + 时序推演覆盖（A8-P1-BE 同口径）；阶段二起评估是否引入 |
| 3 | 基线 CRLF→LF 一次性质规范化 | 接受（语义变更仅 3 端点 + 头部）；无回退 |
| 4 | CI 首次推送 git-data API 误用已证伪全分支重推 | 已核验远端 main 文件 9/9 SHA 匹配 + CI 复跑 SUCCESS；无遗留 |

## 4. 云端真实验证衔接（A8-P1-BE 已知限制，验收后执行）

按 A2/A5 先例，云端环境（`CODER_CLUB_TEST_*` 凭据已就绪）补充真实请求验证，覆盖：search SQL 真实执行（命中/空串/筛选）、contribute 分组与 Feign nickName 联调、401 端到端、topN 边界、categoryId 一级语义确认（另案联动）。执行方：后端实现（B-Impl）在云端环境验证，结果随阶段二任务回执或单独验证回执。

## 5. 状态推进（A8 阶段一收尾）

- **state**：`gate3-a2-impl-accepted` → **`gate3-a8-phase1-accepted`**（新枚举：A8 门户化阶段一后端+前端全部验收闭环；后续阶段二按 A8 设计四阶段表推进）。
- **openFinding `userinfo-fields-mismatch` → closed**（T6 已对齐，残留 0）。
- **契约快照**：`4BFB3C72`（46 端点）零变更（前端消费对齐，非契约变更）。

## 6. 关联

- 任务书：`pm/requirements/2026-08-27/frontend-portalization-task.md`（PR #73）
- 后端验收：`acceptance/backend/2026-08-26/a8-phase1-endpoints-implementation-acceptance.md`（PR #72）
- 签署：`acceptance/frontend/2026-08-27/frontend-portalization-acceptance.md`（PR #76）
- 本验收：`acceptance/frontend/2026-08-27/frontend-portalization-implementation-acceptance.md`

验收：协调 PM，2026-08-27