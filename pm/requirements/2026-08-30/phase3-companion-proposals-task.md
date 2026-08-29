# 任务书：阶段三收尾配套提案起草（X1 消费侧 VO 增补 + NotRoleException 映射同步，一批两提案）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-30
> **执行角色：** 后端评审（B-Review）
> **背景：** A8-P3-BE 回执（PR #97，open 待签署）开放项 ①②，PM 已审阅并授权批量起草：
> - **① X1 消费侧键不匹配（回执 openFinding C1，Critical 治理降级）**：X1 查询层扩展已就位（纯数字 id 匹配），但 `IdentifierUserItemVO` 不含 `id` 字段——消费方（circle 昵称组装、practice 排行）按返回 userName 建键，数字标识（loginId）解析仍降级标识串（云端实测 nickName="1"/"9"）。任务书"顺带修复 practice 排行昵称"声明已由 B-Impl 撤回。
> - **② NotRoleException 映射缺口（治理发现）**：subject/practice 的 GlobalExceptionHandler 无 `NotRoleException` 映射（sa-token 1.46.0 中与 NotPermissionException 为兄弟类）——角色注解失败将 500；circle 已示范修复（→403 语义），需同步。

## 1. 任务 1：X1 消费侧 VO 契约增补提案

- **契约变更**：`IdentifierUserItemVO` **新增 `id` 字段**（Long，auth_user 主键）——响应增字段属向后兼容变更，走 proposal 登记。
- **消费侧改动评估**（提案中明示）：circle 昵称组装 / practice 排行改为按 `id` 建键（identifiers 为数字时），数字标识解析链路真正生效；非数字标识维持 userName 匹配路径。
- **范围**：仅 VO 增字段 + 消费方建键逻辑；不动查询层（X1 已就位）、不动其他端点。
- **验收口径**：practice 排行昵称显示修复（数字 loginId 场景返回真实昵称）作为本提案实现验收项（可引用 A8-P2-BE 已知限制）。

## 2. 任务 2：NotRoleException 映射同步提案

- **变更**：subject/practice 的 GlobalExceptionHandler 增补 `NotRoleException` → 403 映射（对齐 circle 先例与 sa-token 1.46.0 兄弟类语义）。
- **契约面**：错误语义变更（角色失败 500 → 403）须 proposal 登记（各受影响端点的错误响应说明更新；无结构变更）。
- **附带评估**（提案中一并明示）：`NotPermissionException` 现有映射现状与权限注解实际生效路径（关联 openFinding `auth-role-check-gap`——auth SaInterceptor 缺失另案，不在本提案范围，但提案需说明边界）。

## 3. 交付与回执（规则 9）

1. 两提案落 `proposals/backend/2026-08-30/`（单文件两提案或两文件均可，语义清晰即可），经 `codex/backend-contract` PR 合入交接仓库 main。
2. 完成通知带四字段告知 PM；PM 确认后派发 B-Impl 实现（随阶段三验收批次或独立小批次，PM 排期）。
3. 冲突点明示交 PM。

## 4. 验收标准

- [ ] 提案 1：VO 增字段定义 + 消费方建键改动 + practice 排行修复验收口径完整
- [ ] 提案 2：映射变更 + 受影响端点错误语义登记 + auth-role-check-gap 边界说明
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改既有端点/运行时源
- [ ] 合入 main + 通知四字段

## 5. 关联

- A8-P3-BE 回执：PR #97（open，B-Review 签署流程并行继续——本任务书不阻塞回执签署）
- 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`
- 后续：PM 确认两提案 → B-Impl 实现（小批次）→ 验收（可与阶段三验收同批或独立）