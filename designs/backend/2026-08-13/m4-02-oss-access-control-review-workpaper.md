# M4-02 Backend Codex 复核工作底稿

> 角色：Backend Codex
> 日期：2026-08-13
> 任务来源：`pm/requirements/2026-08-13/m4-02-oss-access-control-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-13/m4-02-oss-access-control-report.md`

## 1. 代码级复核（提交 `baa0975` / `5045953`）

| 核对项 | 结果 |
| --- | --- |
| `/oss/upload` `@SaCheckLogin`（匿名 401） | ✅ |
| `/oss/getUrl` 保持匿名 | ✅ |
| `/oss/testGetAllBuckets` 调试开关：`oss.debug.enabled` 默认 false → 业务 404；开启后 `StpUtil.checkRole("admin_user")`（匿名 401 / 非管理员 403 / 管理员 200） | ✅ 开关先于鉴权判断，关闭时信息不泄露 |
| `OssSaTokenConfigure`（读共享会话 roleKeys/permissionKeys）与 `SaTokenWebConfig`（注册 SaInterceptor） | ✅ 与 Subject 模式一致 |
| OSS `GlobalExceptionHandler`：NotLogin→401、NotPermission→403、NotRole→403（兄弟类分别声明） | ✅ |
| sa-token 配置（token-name=Authorization、is-share=true、共享 Redis）与 OSS yaml `oss.debug.enabled` | ✅ |
| pom 修复：maven-compiler-plugin release 21 + spring-boot-maven-plugin | ✅ 范围合理 |
| 策略文档 `docs/backend/2026-08-13-m4-02-oss-access-policy.md`（端点×开放策略） | ✅ |

## 2. 独立测试重跑（本底稿复核时执行）

| 命令 | 结果 |
| --- | --- |
| `FileControllerTest` | **11/11**，BUILD SUCCESS |
| OpenAPI SHA-256 | `7576e28a…` 未变（43/43） |

## 3. 复核结论与备注

- **结论：通过，可签署。**
- [仅供参考] 调试端点 `@RequestMapping` 同时匹配 GET/POST：回执已注明，开关关闭时统一返回业务 404，行为一致。
- 已知限制与回执一致：调试端点默认关闭（`OSS_DEBUG_ENABLED` 可覆盖）；旧 token 访问调试端点 → 403（fail-closed）。

复核签署：Backend Codex，2026-08-13
