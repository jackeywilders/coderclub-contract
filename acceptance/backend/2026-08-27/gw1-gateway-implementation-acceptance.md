# PM 验收：网关引入（GW-1）

> 角色：协调 PM
> 验收日期：2026-08-28
> 任务书：`pm/requirements/2026-08-27/gateway-introduction-task.md`（PR #80）
> 回执：`handoff/backend-to-frontend/2026-08-27/backend-gw1-gateway-introduction-report.md` + `-summary.json`（PR #83）
> 复核签署：`acceptance/backend/2026-08-27/gw1-gateway-introduction-review-signoff.md`（B-Review）
> 状态：**验收通过；契约快照零变更（4bfb3c72）；A8-P1-BE 云端验证待办已随网关链路全部闭环**

## 1. 验收依据（规则 9 远程核验）

- R1/R2：回执（PR #83）+ 签署均已合入交接 main；实施 CoderClub PR #13 **已合入 main**（merge `b960da3`，R2 ✓，API 通道核验）
- 四字段：实施 `5c0fb421` ｜ 回执 `0ad60da0` ｜ PR #13/#83 ｜ R2 已合入

## 2. 验收标准逐项（对照任务书 §5，全绿）

| 项 | 证据 | 结论 |
| --- | --- | --- |
| 6 前缀路由（含 3 预留域） | 路由表 + 预留域 503 实测 + SCG 5.0.0 命名空间适配 | ✅ |
| 白名单 46 端点逐项核对 | 回执 §4 表（7 配置/41 需登录/漏配 0）；B-Review 独立复核 | ✅ |
| 401 语义统一 | 未登录 401 + 与 auth 全局异常逐字一致体 | ✅ |
| loginId 透传 + 覆写防伪造 | 剥除/覆写/白名单不写；集成测试 15 覆盖 | ✅ |
| CORS 统一配置化 | globalcors + OPTIONS 预检放行 | ✅ |
| 兼容性 | 业务服务代码零改动、`@SaCheckLogin` 双保险保留、契约零变更（4bfb3c72） | ✅ |
| 测试 | 网关 69/69 + 全量 20 模块绿；契约测试不受影响 | ✅ |
| 云端联调 9/9 | 401 精确体/白名单登录/token 端点/search/contribute Feign/topN≤20/预留域 503/CORS/oss 白名单——**A8-P1-BE 四项待办（search SQL、Feign 联调、401 e2e、topN 边界）全部闭环** | ✅ |
| sa-token 升级 | 1.45→1.46 全盘 BOM 单点；#916 修复；#968/#970 无影响实证 | ✅ |

## 3. SAP 观察项处置（不阻塞，登记跟进）

| 观察项 | 处置 |
| --- | --- |
| docker 容器级冒烟未执行（本机无 Docker） | **验收补充项**：有 docker 环境后执行 `docker compose up --build` 全栈冒烟（README §7），结果随后续任务回执 |
| auth 类级 `@SaCheckRole` 既有生效缺口 | 登记 openFinding（权限级收敛待服务内处理——网关登录校验已保底） |

## 4. 验收结论

- **验收通过**：网关引入完成，阶段二~四新域统一入口基础就绪；现有服务经网关链路零回归（云体验证）。
- 云端/本地入口切换（域名/负载指向网关 5000）由用户/运维执行（占位符约定）。
- 开工项：前端 vite proxy 单入口调整（配置项，随前端阶段任务或专项执行）。

## 5. 关联

- 任务书 PR #80 · 架构方向 `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §5（PR #79）· 签署 `acceptance/backend/2026-08-27/gw1-gateway-introduction-review-signoff.md`
- 本验收：`acceptance/backend/2026-08-27/gw1-gateway-implementation-acceptance.md`

验收：协调 PM，2026-08-28