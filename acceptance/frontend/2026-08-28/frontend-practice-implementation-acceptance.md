# PM 验收：前端阶段二练习实施（A8-P2-FE）——A8 阶段二收尾

> 角色：协调 PM
> 验收日期：2026-08-28
> 任务书：`pm/requirements/2026-08-28/phase2-frontend-practice-task.md`（PR #88）
> 回执：`handoff/frontend-to-backend/2026-08-28/frontend-practice-report.md` + `-summary.json`（PR #89/#90）
> 复核签署：`acceptance/frontend/2026-08-28/frontend-practice-acceptance.md`（F-Review，PR #91）
> 状态：**验收通过，A8 阶段二（练题域）闭环；state 推进 gate3-a8-phase2-accepted**

## 1. 验收依据（规则 9 远程核验）

| 层级 | 判定对象 | 证据 | 结论 |
| --- | --- | --- | --- |
| R1 | 回执双轨 + 签署文件远端可见 | `handoff/frontend-to-backend/2026-08-28/frontend-practice-*`、`acceptance/frontend/2026-08-28/frontend-practice-acceptance.md` 均在 main | ✅ |
| R2 | 回执（PR #89/#90）、签署（PR #91）合入交接 main；实施前端 PR #15 merge `ed3c56a9`（API 通道核验；F-Review 流程注记：#13/#14 中间版本无残留，最终 #15 生效） | ✅ |
| 四字段 | 实施 `5c05279`（22 commits）/ merge `ed3c56a9`、回执 `aa03fc6`、PR #15/#89/#90/#91、R2 已合入 | summary + 签署一致 | ✅ |

## 2. 验收标准逐项（对照任务书 §5，全绿）

| 项 | 证据（F-Review §3 人链核验） | 结论 |
| --- | --- | --- |
| T1 练习列表页 | 三标签页（专项 `getSpecialPracticeContent` 树→`addPractice`、套卷 `getPreSetContent` 排序分页、未完成 `getUnCompletePractice` 续做）；门户「练题」菜单激活 | ✅ |
| T2 答题页 | 计时器自实现（`?time=` 续计）+ 答题卡 + 四题型作答（简答「本题目不计分」+ trim）+ `judgeable` 对错/「已提交」+ 交卷确认 + 交卷后 400 守卫静默提示 + 竞态令牌 | ✅ |
| T3 分析报告页 | `getReport` 正确率 + `SkillStarBar` 星级（零依赖 el-rate）+ `ScoreDetailDrawer` 明细/解析 + 4 态 | ✅ |
| T4 练习榜 | `getPracticeRankList` 替换占位、空数组不渲染、贡献榜保留 | ✅ |
| 基线 63 端点 | `api-docs-baseline.json` `specSha256=2583b90679ed…`、`endpointCount=63`；`api:check` 通过 | ✅ |
| 验证 | build/test（**24/24**）/api:check/lint 本机全绿 + 前端 CI（run 33145503223）SUCCESS；blob 4/4 逐字节一致 | ✅ |
| 回执双轨 + 四字段 | 双轨落 `handoff/frontend-to-backend/2026-08-28/`（PR #89/#90）；通知字段齐 | ✅ |
| 禁止项 | 未改后端/交接快照与 sync-manifest（2583b906 零变更）；零新依赖（计时/星级自实现）；未改答题判分行为 | ✅ |

## 3. 待联调确认项闭环（F-Review §5，均已核实）

| # | 项 | 结论 |
| --- | --- | --- |
| ① | correctRate 量纲（0-100 vs 0-1） | **闭环：0-100**——后端 `PracticeDetailDomainServiceImpl` L247-250：`correct*100/denominator`（2 位 HALF_UP），前端按 0-100 实现一致 |
| ② | 简答未判分显示语义（ScoreDetailDrawer numClass） | **闭环**：后端 `judgeable=false`（C7）→ 前端琥珀「未判分」兜底为正确语义（与简答不计分一致） |
| ③ | getSpecialPracticeContent 响应递归树 + 请求 `primaryCategoryId` | **闭环**：契约 D1 决策即如此（`CategoryCountNodeVO[]` 树 + `SpecialContentQueryDTO{primaryCategoryId}`），前端按快照实现；参考旧版为过时引用 |
| ④ | 组件级单测受零依赖约束未引 vitest | 接受（同 A8-P1 口径；util 纯函数已单测覆盖） |

## 4. 状态推进（A8 阶段二收尾）

- **state**：`gate3-a8-phase1-accepted` → **`gate3-a8-phase2-accepted`**（阶段二后端+前端全部验收闭环）
- 契约快照：63 端点（`2583B906`）零变更（前端消费对齐）
- 前端基线：46 → 63（前端 `api:check` 对齐）

## 5. 遗留（登记，非本阶段阻塞）

| 项 | 处置 |
| --- | --- |
| CoderClub PR #14 已合入（`2cf74d05`） | 已完成（前轮记录） |
| docker 容器级冒烟 | 验收补充项：有 docker 环境后 `docker compose up --build` 全栈冒烟 |
| categoryId 一级过滤语义（openFinding） | 待后端确认（阶段二/三间另案） |
| practice_detail 唯一索引、PageInfo 架构债、auth role-check 缺口 | openFindings 已登记（3 项 + categoryId） |
| 云端新域入口切换（经网关）+ 前端 vite proxy 单入口 | 随发布评估（A9）执行 |

## 6. 关联

- 任务书 PR #88 · 后端验收 `acceptance/backend/2026-08-27/a8p2-practice-domain-implementation-acceptance.md`（PR #86）· 网关验收 `acceptance/backend/2026-08-27/gw1-gateway-implementation-acceptance.md`（PR #86）
- 签署 `acceptance/frontend/2026-08-28/frontend-practice-acceptance.md`（F-Review，PR #91）
- 本验收：`acceptance/frontend/2026-08-28/frontend-practice-implementation-acceptance.md`

验收：协调 PM，2026-08-28