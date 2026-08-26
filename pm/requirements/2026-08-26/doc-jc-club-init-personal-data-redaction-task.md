# 任务书：doc_jc-club-init.sql 个人数据脱敏（A5）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-26
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **先例：** `6f12670 chore(schema): redact real IP in doc_jc-club-init.sql per rule 8`（2026-08-15 已脱敏真实 IP；本轮继续处理个人标识字段）
> **类型：** 数据脚本合规修订（不涉及接口/鉴权/错误码/契约，**无需 proposal**，直接派发实施）

## 1. 目标

对后端项目初始化脚本 `docs/database/schema/doc_jc-club-init.sql`（1160 行，含 `auth_user` 等表 19 条用户示例数据）中残留的个人数据标识字段做脱敏处理，使脚本不含任何可辨识真实个人数据（规则 8 合规，防公开泄露）。

## 2. 实施边界（仅以下范围，禁止扩大）

1. **文件**：`G:/Dev/backend/Club/CoderClub/docs/database/schema/doc_jc-club-init.sql`（仅此文件）。
2. **字段范围**（PM 已勘察表结构）：
   - `user_name`（登录名，19 处样例，可能为真实姓名/手机号形态）
   - `nick_name`（昵称，19 处）
   - `email`（邮箱，19 处）
   - `phone`（手机号，19 处）
   - `password`（样例口令，如为真实口令样本须替换）
   - `ext_json`（扩展字段——**重点检查**：微信登录 openid/unionid 等真实标识如藏于此，须一并脱敏；如确无，在回执中记录"检查无"证据）
   - 其他潜在个人数据形态（身份证号、真实地址等，如存在一并处理）
3. **样本值约定**（保持 SQL 可执行、可辨识为样本）：
   - `phone` → `1380000000X`（X=1..19，示范保留号段）
   - `email` → `userXX@example.com`（XX=01..19）
   - `user_name`/`nick_name` → `test-user-XX` / `示例用户XX`
   - `password` → 统一脱敏样本口令（如 `{noop}demo123`，按表列实际存储格式调整，**回执中不写生成规则之外的真实值**）
   - `ext_json` 内标识 → 语义化占位符（`<sample-openid>` 风格，遵循 `docs/agents/sensitive-data-conventions.md`）
4. **保持脚本语义**：INSERT 行数、列数、表结构/DDL、注释结构不变；样本值须满足列类型与约束（可正常插入执行）；不影响非个人数据内容（菜单/权限/业务字典等不动）。

## 3. 禁止事项

- 不修改任何 `CREATE TABLE`/DDL/约束/索引；不修改接口、契约、鉴权、错误码。
- 不修改交接仓库 `api/` 快照、`status/sync-manifest.json` 及任何治理文件（本任务与契约无关，快照零变更）。
- 不回执、不落盘任何真实个人数据值；回执中出现的样本形态仅限 §2.3 约定格式。
- 不触碰生产数据库；仅修订脚本文件。

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送到后端仓库（提交信息按 Conventional Commits，如 `chore(schema): redact personal data in doc_jc-club-init.sql (A5)`）。
2. 回执双轨提交到交接仓库 `handoff/backend-to-frontend/2026-08-26/`：Markdown 正文（来源与提交哈希表、字段覆盖清单、脱敏前后样本值对比（仅样本形态）、扫描证据、`ext_json` 检查结论）+ 同目录 `*-summary.json`（按 `_template-task-receipt-summary.json` 模板；`taskId= A5`、`contractSnapshotSha256` 填 `8ebcda53`（当前快照，核实为零变更）、`verificationResult` 填扫描/插入验证结果）。
3. 完成通知带规则 9 四字段（实施 SHA、回执 SHA、PR 号、R2 状态），告知后端评审复核签署；回执经 `claude/backend-proposals` PR 合入交接仓库 main（governance-check 自动合并）。
4. 后端评审复核签署后通知 PM；PM 验收后推进状态（本任务不触发快照同步）。

## 5. 验收标准

- [ ] `auth_user` 等表个人标识字段（user_name/nick_name/email/phone/password/ext_json）无真实数据残留
- [ ] 敏感模式扫描零命中：真实手机号（`1[3-9][0-9]{9}`）、真实邮箱域（非 example.com 等样本域）、openid/unionid 真实形态、身份证号形态
- [ ] SQL 可执行性保持（样本值满足格式/约束；INSERT 数量与结构不变）
- [ ] 未修改 DDL/表结构；未改契约
- [ ] 回执双轨落 `handoff/backend-to-frontend/2026-08-26/`，通知带四字段远端证据

## 6. 关联

- 规则 8 / 脱敏约定：`docs/agents/sensitive-data-conventions.md`；仓库治理 `AGENTS.md`
- 先例提交：`6f12670`（IP 脱敏，2026-08-15）
- 后端评审复核：签署回执（`acceptance/backend/`）后转 PM 验收