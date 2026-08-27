# GW-1 网关引入——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-28
> 任务书：`pm/requirements/2026-08-27/gateway-introduction-task.md`（PR #80）
> 回执：`handoff/backend-to-frontend/2026-08-27/backend-gw1-gateway-introduction-report.md` + `-summary.json`
> 工作底稿：`designs/backend/2026-08-27/gw1-a8p2-review-workpaper.md`（§2 GW-1 部分）
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `5c0fb421`（CoderClub PR #13，**已合入 main** merge `b960da3`，CI 全绿）经人链核验与独立复验与任务书/架构方向 §5 相符：

- [x] **白名单逐项核对**：7 项配置（/auth/login、/auth/register、/auth/wx-login、/oss/upload、/oss/getUrl + 2 actuator）按契约 46 端点逐项（回执 §4 表 1-46）：匿名集合 = 白名单 5 项、41 需登录、漏配 0；`oss/upload` 服务内 `@SaCheckLogin` 双保险放行不构成回退
- [x] **401 语义**：未登录 → 401 + `{"success":false,"code":401,"message":"未登录或Token已过期","data":null}`（与 auth 全局异常逐字一致）
- [x] **loginId 透传/覆写**：剥除客户端同名头防伪造；白名单剥除不写；`SaReactorSyncHolder` 上下文窗口（集成测试 15 覆盖）
- [x] **6 前缀路由**（含 practice/circle/interview 预留 503）+ StripPrefix=0 + SCG 5.0.0 新命名空间
- [x] **CORS 统一**（占位符配置 + OPTIONS 预检放行）
- [x] **sa-token 1.45→1.46 全盘升级**（BOM 单点，修复 #916 NoSuchMethodError；Lettuce 验证 #970 无影响）
- [x] **业务服务代码零改动**、`@SaCheckLogin` 双保险保留、契约零变更（`4bfb3c72`）
- [x] **独立复验**：Gateway **69/69** BUILD SUCCESS（回执声称 69 一致）
- [x] 云端联调 9/9（401 精确体/白名单登录/token 受保护端点/search/contribute Feign/topN≤20/预留域 503/CORS/oss 白名单）——回执声明 + CI + 复验佐证

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `5c0fb421`（`5c0fb421be9d3f2e6d0c54d44e36f5b7cd10a63f`） |
| 回执提交 SHA | `0ad60da0`（summary 记录） |
| PR 号 | CoderClub PR #13（已合入 main `b960da3`，R2 ✅） |
| R2 状态 | **已合入 main**（merge `b960da3`）；回执已合入交接仓库 main |

## 3. SAP 观察项（打包转 PM/验收，不阻塞）

- **docker 容器冒烟**：本机无 Docker（`Get-Command docker`=False）→ 容器级实证列为验收补充（README §7 `docker compose up --build` 全栈冒烟）；mvn 层复验本会话已完成。
- **auth 类级 `@SaCheckRole` 生效缺口**（回执 §11 观察，非本任务引入）：auth 未注册 SaInterceptor；网关登录校验级已保证有效 token，权限级收敛待服务内处理。

## 4. 关联

- 任务书 PR #80 · 架构方向 PR #79 §5 · 实现计划 `docs/superpowers/plans/2026-08-27-gateway-introduction-plan.md`
- 本签署：`acceptance/backend/2026-08-27/gw1-gateway-introduction-review-signoff.md`

签署：后端评审（B-Review），2026-08-28