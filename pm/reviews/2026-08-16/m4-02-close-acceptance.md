# M4-02 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-16
> **任务：** M4-02 OSS 访问控制
> **任务书：** `pm/requirements/2026-08-13/m4-02-oss-access-control-task.md`
> **执行回执：** `handoff/backend-to-frontend/2026-08-13/m4-02-oss-access-control-report.md`
> **复核签署：** 后端评审（B-Review，原 Backend Codex），2026-08-13
> **验收结论：** ✅ **通过，M4-02 关闭**

## 关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | OSS 端点策略文档（上传/查询/调试逐项明确）与实施提交存在 | `docs/backend/2026-08-13-m4-02-oss-access-policy.md`；实施提交 `baa0975`、补充提交 `5045953` | ✅ |
| 2 | 未登录/登录态/越权三态测试通过，既有测试全绿 | FileControllerTest 11/11；全量回归 101/101 BUILD SUCCESS | ✅ |
| 3 | 回执含原始命令输出与提交哈希，后端评审复核签署 | 回执 §4 原始输出；签署 2026-08-13（工作底稿 `designs/backend/2026-08-13/m4-02-oss-access-control-review-workpaper.md`） | ✅ |

## 关键核验

- **契约影响**：OpenAPI SHA-256 未变（`7576e28a…`，43/43）——OSS 端点鉴权行为变更由 M4-02 任务批准。
- **端点策略**：`/oss/upload` 登录（匿名 401/登录 200）、`/oss/getUrl` 匿名、`/oss/testGetAllBuckets` 调试开关 + `admin_user`（开关先于鉴权判断，关闭时不泄露信息）。
- **真实环境**：真实复核 5 场景全过（匿名 upload 401、登录 upload 200 MinIO 上传成功、getUrl 200、调试端点默认关 404）；Nacos `coder-club-oss-dev.properties` 已补共享 Redis 与 sa-token 配置。
- **401/403 一致性**：OSS handler 补 `NotLoginException`→401、`NotPermissionException`/`NotRoleException`→403。

## 已知限制（验收知悉，不阻塞关闭）

1. 调试端点默认关闭（`oss.debug.enabled=false`，环境变量可覆盖）。
2. 共享会话依赖 Auth；旧 token 访问调试端点 → 403（fail-closed）。
3. OSS pom 显式声明 `maven-compiler-plugin`（release 21）与 `spring-boot-maven-plugin`，其余服务不受影响。

## 备注

- 无阻塞项；任务书 §4 关闭条件 1-3 全部满足。
- 验收结论写入 `status/pm.json`（M4-02 验收通过）。
