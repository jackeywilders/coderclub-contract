# M4-01 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-16
> **任务：** M4-01 细粒度角色/权限矩阵
> **任务书：** `pm/requirements/2026-08-13/m4-01-fine-grained-permission-task.md`
> **执行回执：** `handoff/backend-to-frontend/2026-08-13/m4-01-fine-grained-permission-report.md`
> **复核签署：** 后端评审（B-Review，原 Backend Codex），2026-08-13
> **验收结论：** ✅ **通过，M4-01 关闭**

## 关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | 权限矩阵文档（端点 × 角色 × 行为）与实施提交存在 | `docs/backend/2026-08-13-m4-01-permission-matrix.md`；实施提交 `fbac8a8`、种子 `8ee6919`、修复 `eb17d57`、类型统一 `a67e274` | ✅ |
| 2 | 匿名/普通用户/管理员三态 401/403 测试通过，既有测试全绿 | SubjectContractTest 49/49、AuthContractTest 8/8；全量回归 103/103 BUILD SUCCESS；真实 DB 三态：匿名 401 / 普通用户 403 / 管理员 200 | ✅ |
| 3 | 回执含原始命令输出与提交哈希，后端评审复核签署 | 回执 §4/§8 原始命令与输出；签署 2026-08-13（工作底稿 `designs/backend/2026-08-13/m4-01-fine-grained-permission-review-workpaper.md`） | ✅ |

## 关键核验

- **契约影响**：OpenAPI SHA-256 未变（`7576e28a…`，43 路径 / 43 操作）——鉴权行为变更由 M4-01 任务批准，无需提案。
- **实施质量**：9 个 Subject 写端点 `@SaCheckPermission`、Auth role/permission 收紧 `@SaCheckRole("admin_user")`、`permissionIds` 旧会话键无残留读取方、`eb17d57` 空集合守卫 + TDD 回归（无权限用户登录缺陷已修复）。
- **真实环境**：真实 DB 复核确认矩阵语义正确（匿名 401 / 普通用户 403 / 管理员 200）；种子数据应用由用户执行。

## 已知限制（验收知悉，不阻塞关闭）

1. 运行库权限数据配置需在共享 dev 库执行对应 INSERT（`init.sql` 已含，未擅自改动运行库）。
2. 权限键粒度：Subject 写端点按 9 权限键校验，读端点登录即可。
3. 会话依赖 Auth 写入共享会话；旧 token 无会话数据 → 写端点 403（fail-closed）。
4. `/auth/role`、`/auth/permission` 收紧为 admin_user（行为变更属 M4-01 目标）。

## 备注

- 无阻塞项；任务书 §4 关闭条件 1-3 全部满足。
- 验收结论写入 `status/pm.json`（M4-01 验收通过）。
