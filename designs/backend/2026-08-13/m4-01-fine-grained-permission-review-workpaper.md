# M4-01 Backend Codex 复核工作底稿

> 角色：Backend Codex
> 日期：2026-08-13
> 任务来源：`pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md`
> 回执：`handoff/backend-to-frontend/2026-08-13/m4-01-fine-grained-permission-report.md`

## 1. 代码级复核（提交 `fbac8a8` / `8ee6919` / `eb17d57` / `a67e274`）

| 核对项 | 结果 |
| --- | --- |
| 9 个 Subject 写端点 `@SaCheckPermission` 齐全（subject:add/update/remove、category:add/update/delete、label:add/update/delete） | ✅ 逐端点 grep 确认 |
| Auth role/permission 控制器 `@SaCheckLogin` → `@SaCheckRole("admin_user")` | ✅ 与 AuthUserManageController 一致 |
| `permissionKeys` 会话键替换：旧会话键 `permissionIds` 无读取方残留（仅剩 DTO/方法名合法引用） | ✅ 全库 grep 确认 |
| `eb17d57` 空权限集合守卫（`!permissionIdSet.isEmpty()`）+ TDD 回归测试 | ✅ 代码与测试均在 |
| 403 一致性：Subject/Auth `NotPermissionException`/`NotRoleException` → HTTP 403 + code 403 + 统一响应体 | ✅ 三服务 handler 逐项确认 |
| `init.sql` 种子：9 权限键 + admin_user（role_id=1）分配 9 行；normal_user 零写权限 | ✅ |
| 权限矩阵文档 `docs/backend/2026-08-13-m4-01-permission-matrix.md`（端点×角色×行为） | ✅ 质量良好 |

## 2. 独立测试重跑（本底稿复核时执行）

| 命令 | 结果 |
| --- | --- |
| `SubjectContractTest` | **49/49**，BUILD SUCCESS |
| `AuthContractTest` | **8/8**，BUILD SUCCESS |
| OpenAPI SHA-256 | `7576e28a…` 未变（43/43） |

## 3. 复核结论与备注

- **结论：通过，可签署。**
- [仅供参考] `SubjectSaTokenConfigure` 使用 `StpUtil.getSession()` 而非 `getSessionByLoginId(loginId)`：当前流程（`@SaCheckPermission` 前置登录校验）下等价，无实际问题。
- 已知限制与回执一致：运行库权限数据需由运维/PM 应用种子；旧 token（无会话角色数据）→ 写端点 403（fail-closed，安全侧正确）。

复核签署：Backend Codex，2026-08-13
