# Proposal：NotRoleException 映射同步（subject/practice 全局异常处理器 → 403）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-30
> **任务书：** `pm/requirements/2026-08-30/phase3-companion-proposals-task.md`（PR #99，提交 `c3c3c958`）任务 2
> **背景：** A8-P3-BE 回执 §6.2 治理发现（PR #97）；复核签署 §3.2（PR #100）；circle 先例 = A8-P3 X3（`d9eb64f`，已合入 main `583b4bb`）
> **状态：** 待 PM 确认

## 1. 背景与问题（治理发现事实链）

- subject/practice 的 `GlobalExceptionHandler` **无 `NotRoleException` 映射**（本会话实读核验：两服务处理器有 `NotLoginException`/`NotPermissionException`/`Exception` 等映射，`NotRoleException` 全库零命中）。
- **sa-token 1.46.0 中 `NotRoleException` 与 `NotPermissionException` 为兄弟类**（不再是父子）——角色注解校验失败将穿透既有 `NotPermissionException` 映射、落入 `Exception` 兜底 → **500**（应为 403）。
- 触发前提是服务内存在 `@SaCheckRole` 端点：circle 已示范（X3，`@SaCheckRole("admin_user")` + `NotRoleException → 403` 映射 + 契约测试 403 用例）；subject/practice 当前无角色注解端点（见 §3 偏差明示）。

## 2. 变更定义

| 项 | 定义 |
| --- | --- |
| 代码变更 | subject / practice 两个 `GlobalExceptionHandler` 各增补一个映射：`@ExceptionHandler(NotRoleException.class)` + `@ResponseStatus(HttpStatus.FORBIDDEN)` → `ResponseResult.fail(ResultCodeEnum.FORBIDDEN.getCode(), "无权限访问")` |
| 对齐基准 | 与两服务**既有** `NotPermissionException` 映射（`GlobalExceptionHandler:88-92`）及 circle 先例（`GlobalExceptionHandler:100-104`）**逐字同形态**——三服务 403 语义/文案完全一致 |
| 契约面 | **per-endpoint 零变更**（见 §3）；错误语义登记于本提案（角色校验失败 = 403「无权限访问」，未来任何角色注解端点生效时语义既定） |

## 3. 契约面与任务书偏差明示（交 PM）

- **任务书假设**："各受影响端点的错误响应说明更新"。
- **核验事实**：subject/practice 当前**零 `@SaCheckRole` 端点**（实读全量控制器）→ **受影响端点清单 = 空** → 快照 per-endpoint 零变更、无错误响应说明需逐端点更新。
- **处置建议**：本提案按**防御性同步**定稿——映射先行到位，一次性消除"未来任一服务新增角色注解即踩 500"的隐患（生产代价模型：一个 handler 的成本 vs 一类线上 500）；偏差如实列示，请 PM 知悉并确认处置口径。

## 4. 边界说明（任务书要求）

1. **subject 权限注解现状**：subject 现有 **9 个 `@SaCheckPermission` 端点**（`subject:add/remove/update`、`subject:category:add/update/delete`、`subject:label:add/update/delete`），其 `NotPermissionException → 403` 映射已在实际服役（SaInterceptor + SubjectSaTokenConfigure permissionKeys 链路），**不受本提案影响**。
2. **auth 不在本提案范围**：auth 服务缺 SaInterceptor 致类级 `@SaCheckRole("admin_user")` 注解不生效（openFinding `auth-role-check-gap`，GW-1 登录校验级已保底）——**另案处理不变**，本提案不触及 auth。
3. **不补角色注解**：不为既有端点叠加 `@SaCheckRole`（与权限注解构成双重门禁，普通用户行为将变更且未评估）——范围外。
4. circle 先例引用：X3 实现（`CircleSaTokenConfigure` roleKeys 解析 + 403 契约用例）为本提案的同款模式来源。

## 5. 验收口径

1. subject/practice 各增 `NotRoleException → 403` 单测（响应体 `{success:false, code:403, message:"无权限访问"}`），对齐 circle 契约用例形态。
2. 既有测试零回归（subject/practice 全模块）。
3. 契约面零变更确认：`api/` 快照与 `sync-manifest` 不动；74 路径源文档无结构差异。

## 6. 待 PM 确认项

| # | 项 | 建议 | 需 PM 确认 |
| --- | --- | --- | --- |
| N1 | 映射变更（两服务各一 handler，同形态对齐） | 按本提案 | ✅ |
| N2 | 偏差处置（受影响端点=空，防御性同步 + 语义预登记） | 按 §3 | ✅ |
| N3 | 边界（不补角色注解 / auth 另案不变） | 按 §4 | ✅ 知悉 |

## 7. 约束遵守声明

- 仅两个异常处理器各增一个映射；**未改既有端点/字段/鉴权/既有错误语义**（403 文案与各服务既有权限失败口径一致）；未动 `api/` 快照与 `sync-manifest`；未改运行时源（本提案为文档，实现由 B-Impl 执行）。
- 示例语义化（规则 8），无真实环境信息。

## 8. 关联与后续

- 任务书 PR #99 · A8-P3 回执 PR #97 · 签署 PR #100 · X3 先例 CoderClub PR #15（merged `583b4bb`）
- 后续：PM 确认（N1-N3）→ B-Impl 小批次实现（可与提案①同批，PM 排期）→ 回执 → 签署 → 验收

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-30
