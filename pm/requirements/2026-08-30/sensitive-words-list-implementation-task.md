# 任务书：敏感词词库 list 端点实现（B-Impl 小批次）

> 派发角色：协调 PM
> 派发日期：2026-08-30
> 执行角色：后端实现（B-Impl）
> 提案（已 PM 确认）：`proposals/backend/2026-08-30/sensitive-words-list-proposal.md`（PR #107，R2 main）；PM 决策：`pm/reviews/2026-08-30/sensitive-words-list-proposal-decision.md`（L1-L3 全确认）
> 批次：小批次（单分支单 PR）

## 1. 任务明细

按提案 §2/§3/§6 逐条执行：

1. **实体**：`SensitiveWordsEntity` 增 `createdTime` 字段（MyBatis-Flex 既有 createdTime 自动填充机制生效——save 端点逻辑零改动，新增词自动落时间；存量行 DB 侧已为 NULL）。
2. **端点**：`POST /circle/sensitive/words/list`——`@SaCheckRole("admin_user")`（403 由既有 NotRoleException 映射承接）；**无请求体**；返回 `ResponseResult<List<SensitiveWordItemVO>>`，排序 **type ASC, id ASC**；**只读，不触碰 DFA 词库缓存重建**。
3. **VO**：新增 `SensitiveWordItemVO`（`id: Long, words: String, type: Integer, createdTime: string|null`）——字段名 **`words`**（复数，对齐表列/实体/save DTO，任务书原 `word` 笔误已勘误）。
4. **契约测试**：200 全量（断言排序 type ASC + id ASC 与字段面）/ 401 未登录 / 403 非管理员（真实拦截链，对齐 circle 既有 403 用例形态）；数据语义用例：存量行 `createdTime=null` 如实返回、save 新词后 list 可见且带时间。
5. **schema 文档同步**：`docs/database/schema/doc_jc-club-init.sql` 中 `sensitive_words` 建表语句补 `created_time datetime DEFAULT NULL COMMENT '创建时间' AFTER type` 列（与用户 2026-08-30 云端已执行 DDL 一致——提案 §3 登记，A1 模式）。
6. **源契约文档**：`docs/api/coderclub-openapi.json` 登记 75 路径 + `SensitiveWordItemVO` schema（required = id/words/type）；回执登记 LF SHA before/after（before = `BF59FECD7DA3A97BBC86CA589AA2D0E21CCD450444A63CE82B8AD040E49382B4`）。

## 2. 交付与回执（规则 9）

1. 分支 `feat/backend-sensitive-words-list` → CoderClub PR；CI 全绿后由用户/B-Review 合入（仓库惯例）。
2. 回执双轨：`handoff/backend-to-frontend/2026-08-30/`（按创建日期，Markdown + `*-summary.json` 模板字段齐全），完成通知四字段。
3. 快照衔接：实现合入后 PM 验收批次微同步 74→**75**，随后派发 F-Impl 第二批（管理端敏感词管理页）。

## 3. 约束

- 只读端点：不触碰词库缓存/DFA 重建；save/remove 既有语义与契约零变化；不补 created_by 列（另案专项）。
- 不改 `api/` 快照与 `status/sync-manifest.json`（PM 验收后微同步）；无其他 DDL（created_time 列用户已云端执行，本批仅 schema 文档同步）。
- 规则 8 敏感信息占位符与 Conventional Commits 照常。

## 4. 关联

- 提案 PR #107 · PM 决策（L1-L3）· 任务书 PR #106 · F-Impl 第一批（执行中）· DDL 用户执行登记（提案 §3，A1 模式 2026-08-30）
