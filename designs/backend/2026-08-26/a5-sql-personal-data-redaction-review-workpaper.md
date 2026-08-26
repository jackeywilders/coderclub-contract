# A5 doc_jc-club-init.sql 个人数据脱敏——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/doc-jc-club-init-personal-data-redaction-task.md`（PR #54 已合入 main）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a5-sql-personal-data-redaction-report.md` + `-summary.json`（PR #55 已合入 main）
> 实施分支：`feat/backend-a5-sql-personal-data-redaction`（后端项目 CoderClub，PR #10，head `34ca345`）

## 1. 人链核验：实施提交存在性（verification-workflow §5）

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 提交对象存在 | `git rev-parse 34ca3450734ab4538de25c311cec7f48728ea2b0` 成功；本地 checkout `review/a5-34ca345` 复验 | ✅ |
| 远端 PR 可见（R1） | CoderClub PR #10（open，base main，head `34ca345`） | ✅ |
| CI | build-and-test success + sensitive-scan success | ✅ |
| 与回执声明一致 | 实施提交 `34ca345`、回执 `0bb44b2`→tip `f02e20c`（PR #55 合入交接仓库 main） | ✅ |

## 2. 代码/数据级复核（diff：仅 1 文件 336+/336- = 18 条 INSERT 整行替换 + openid 占位替换）

| 核对项 | 结果 |
| --- | --- |
| 文件范围 | 仅 `docs/database/schema/doc_jc-club-init.sql`（1160 行） | ✅ |
| `user_name` | 18 条 openid 形态 → `test-user-01..18`（18 条 INSERT 全量替换） | ✅ |
| `nick_name` | → `示例用户01..18`；`share_message` content 内嵌昵称 4 处 → 对应样本昵称（`示例用户` 全文件 22 处 = 18 INSERT + 4 content） | ✅ |
| `email` | 唯一真实 `charliefei839@gmail.com` → `userXX@example.com`（18 条） | ✅ |
| `phone` | 唯一真实 `13277779999` → `138000000XX`（18 条，11 位合法形态） | ✅ |
| `password` | → 统一 `{noop}demo123`（18 条，与 varchar(64) 兼容） | ✅ |
| `ext_json` | 全表 NULL 无值——检查无 openid/unionid 藏匿 | ✅ |
| openid 占位 | 6 个唯一 openid → `<sample-openid-01..06>`，**341 处**（出现次数口径，与回执逐字一致）；`oYA4Ht*` 真实前缀残留 0 | ✅ |
| 非个人数据 | DDL/表结构/注释/业务字典零改动 | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `34ca345`；非回执声明转录）

| 检查项 | 结果 |
| --- | --- |
| 真实手机号正则 `1[3-9]\d{9}` | 18 命中，全部为 `138000000XX` 样本；非 138 开头形态 0 | ✅ |
| 非 example.com 邮箱域 | 0（唯一 `@2x.png` 为头像文件名，正则已排除） | ✅ |
| `oYA4Ht` openid 前缀 | 0；身份证形态 `\d{17}[\dXx]` 0 | ✅ |
| 原值残留 | gmail / 13277779999 / 鸡翅 / 鸡腿 / 老鸽 / charlief 全 0 | ✅ |
| `userXX@example.com` / `138000000XX` / `{noop}demo123` 样本覆盖 | 各 18 条 | ✅ |
| SQL 结构 | 行数 1160 不变；INSERT/VALUES/`(` 行单引号成对 0 异常；圆括号 open=close=1349；`BEGIN`/`COMMIT` 25/25（基线 main 同 25/25） | ✅ |
| auth_user INSERT 行数 | 前后均 18（基线即 18，未增删） | ✅ |
| DDL 未动 | git diff 无 `CREATE TABLE`/`ALTER`/`COMMENT` 行改动 | ✅ |

## 4. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明（字段覆盖、341 处 openid、扫描零命中、SQL 可执行性、DDL 未动、快照零变更）逐项一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] 任务书 §1 称"19 条用户示例数据"，基线与实施均为 **18 条**（`INSERT INTO auth_user` 前后一致）——任务书表述口径与基线不符，非实施问题；脱敏覆盖完整（18 条全量）。
- [仅供参考] 回执 §3 称 BEGIN/COMMIT "24 对配对"，独立复验为 **25/25**（line 级统计，基线 main 同样 25/25）——回执数字小口径差异，结构一致性成立，不构成实质不符。
- [仅供参考] 回执 summary `receiptCommitSha: 0bb44b2` 早于回执 tip `f02e20c`（PR #55 合入 main 的提交）——引用类小瑕疵（同 A2 先例），建议 B-Impl 或 PM 验收时补正，不阻塞签署。

复核签署：后端评审（B-Review），2026-08-26