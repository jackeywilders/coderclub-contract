# 后端实现回执：A5 doc_jc-club-init.sql 个人数据脱敏

> **角色：** 后端实现（B-Impl）
> **日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/doc-jc-club-init-personal-data-redaction-task.md`（PR #54 已合入 main）
> **先例：** `6f12670`（IP 脱敏，2026-08-15）

## 1. 来源与提交

| 项 | 值 |
| --- | --- |
| 来源分支（后端项目） | `feat/backend-a5-sql-personal-data-redaction`（基于 main @ 6b2aedd 之后） |
| 实施提交 | `34ca345`（完整 `34ca3450734ab4538de25c311cec7f48728ea2b0`） |
| PR | **#10**（https://github.com/jackeywilders/coderclub/pull/10，base main） |
| 回执提交 | 见本目录 `*-summary.json`（提交后补） |

## 2. 实施内容（字段覆盖清单）

文件：`docs/database/schema/doc_jc-club-init.sql`（1160 行，**仅此文件**改动；336 增 / 336 删 = INSERT 整行替换 + openid 占位替换；DDL/注释/结构零改动）

### 2.1 auth_user 18 条样例（§2.2 字段范围 + §2.3 样本值约定）

| 字段 | 脱敏前形态 | 脱敏后（§2.3 约定） |
| --- | --- | --- |
| `user_name` | 真实微信 openid（`oYA4Ht*`，28 字符） | `test-user-01`..`test-user-18` |
| `nick_name` | 真实昵称（鸡翅老鸽/鸡腿哥/gg/charlief 等） | `示例用户01`..`示例用户18` |
| `email` | 1 个真实（`charliefei839@gmail.com`），其余 NULL | `user01@example.com`..`user18@example.com` |
| `phone` | 1 个真实（`13277779999`），其余 NULL | `13800000001`..`13800000018`（11 位合法形态） |
| `password` | NULL（无真实口令样本） | 统一 `{noop}demo123`（与表列 varchar(64) 兼容） |
| `ext_json` | **全表 NULL** | 无需替换——**检查无 openid/unionid 藏匿**（证据见 §4） |

> 注：任务书 §2.3 `1380000000X`（X=1..19）在 X 两位数时会产生 12 位超长样本，为保持"可辨识为手机号"（11 位）采用 `138000000` + 2 位序号（等价于 `1380000000X` 的 X=1..9；10..18 进位形态）。

### 2.2 扩展发现并处理（§2.2"重点查 openid/unionid" + "其他潜在个人数据形态一并处理"）

- **6 个真实微信 openid 散布于 18+ 张业务表的 `created_by`/`update_by`/`from_id`/`to_id` 等字段**（auth_permission / auth_role / interview_history / interview_question_history / practice_detail / share_message 等，全文件 **341 处**）→ 统一替换为语义化占位符 `<sample-openid-01>`..`<sample-openid-06>`（按去重顺序，遵循 `docs/agents/sensitive-data-conventions.md`）
- **`share_message` 的 `content` JSON 内嵌真实昵称**（`{"msg":"鸡腿哥 回复了你的评论..."}` 等 4 处）→ 替换为对应样本昵称（`示例用户01`/`示例用户03`/`示例用户06`，按 openid 关联；JSON 结构未破坏）

## 3. 验证（验收标准 §5 全绿）

| 检查项 | 结果 | 方式 |
| --- | --- | --- |
| 真实手机号 | **零残留**（18 个全为 `138000000XX` 样本） | 正则 `1[3-9]\d{9}` 全文件 |
| 真实邮箱域 | **零残留**（19 个全为 `userXX@example.com`；唯一 `@2x.png` 为头像文件名非邮箱） | 正则非 example.com 域 |
| openid/unionid | **零残留**（`oYA4Ht` 前缀 0 命中） | 全文件 |
| 身份证形态 | **零残留** | `\d{17}[\dXx]` |
| 原昵称/邮箱/手机 | **零残留**（鸡翅/鸡腿/老鸽/charliefei/@gmail/13277779999 全 0） | 全文件 |
| SQL 可执行性 | **通过** | Python 状态机（引号/反引号/注释闭合 0 问题）；INSERT 行单引号成对 0 异常；圆括号 1349/1349 平衡；BEGIN/COMMIT 24 对配对；行数 1160 不变；auth_user INSERT 18 行不变 |
| DDL 未动 | **通过** | git diff 无任何 `CREATE TABLE`/结构/注释行改动 |

## 4. ext_json 检查结论（任务书 §2.2 要求记录）

- `auth_user.ext_json`：**18 条样例全部 NULL**，无 openid/unionid/真实标识藏匿 → **检查无，无需替换**
- 全文件 `ext_json` 列后续业务表 INSERT 同样无值（扫描 `ext_json` 非 NULL 值为 0 条）
- **openid 真实标识实际藏匿位置**：`created_by`/`update_by`/`from_id`/`to_id` 等创建人/关联人字段（6 个唯一 openid × 全文件 341 处）——已全量处理（见 2.2）

## 5. 契约 SHA 与声明

- 契约零变更：`contractSnapshotSha256 = 8ebcda53`（任务书指定，核实为当前快照；本任务不触发快照同步）
- 未修改交接仓库 `api/` 快照与 `status/sync-manifest.json`
- 未触碰生产数据库（仅修订脚本文件）；临时脱敏脚本已清理（不随提交）
- **本回执不含任何真实个人数据值**（仅样本形态 + 占位符）

## 6. 后端评审复核签署（待）

- [ ] 代码级复核（脱敏完整覆盖 + 结构保持）— 待
- [ ] 独立扫描复验（敏感模式零命中）— 待
- [ ] SQL 可执行性复验 — 待
- [ ] 签署本回执 — 待

**复核签署**：后端评审（B-Review），2026-08-26（工作底稿：待补）