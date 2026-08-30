# PM 决策：敏感词词库 list 端点提案确认（L1-L3）

> 决策角色：协调 PM
> 决策日期：2026-08-30
> 提案：`proposals/backend/2026-08-30/sensitive-words-list-proposal.md`（PR #107，实施提交 `ccecd62`，R2 main，MCP 核验）
> 任务书：`pm/requirements/2026-08-30/sensitive-words-list-proposal-task.md`（PR #106）
> 状态：**提案确认通过，B-Impl 小实现任务书随本轮派发**

## 1. 决策结果

| 项 | 内容 | 决策 |
| --- | --- | --- |
| L1 | 响应字段面 `{id, words, type, createdTime}`（required = id/words/type，createdTime 可 null）+ **DDL 已由用户执行登记（A1 模式，2026-08-30 云端）** + created_by 审计补全另案 | ✅ 按提案 |
| L2 | 查询口径 = **全量列表**（非分页），排序 type ASC + id ASC | ✅ 按提案（任务书预留 PM 拍板项，就此定稿） |
| L3 | 边界：只读不触 DFA 重建 / save-remove 既有语义零变化 / 受影响端点无 | ✅ 知悉 |

## 2. 决策理由

1. **L1**：字段面满足管理链闭环（列表含 id → 删词可运营）；存量行 `createdTime=null` 如实展示不回填假数据，诚实口径正确。DDL 由用户执行属 A1 既有模式（先例：A1 `subject_category.sort`，运行时 DDL 由用户/运维执行、PM 登记），提案已完整登记执行时间与环境范围。`created_by` 未补列的评估成立——补列 + save 语义变更应另案专项，不随本批。
2. **L2**：全量列表量级评估有说服力——种子数据数行、DFA 启动即全量驻内存（同为全量口径先例）、千级词库全量 JSON 仅几十 KB；管理表格需全量盘点与跨黑/白名单操作，分页反而引入翻页状态成本。**偏离任务书默认推荐（分页）的偏差予以确认**——任务书明确两案均可、提案明示即定。万级再评估分页（提案 §4 权衡已记录在案）。
3. **L3**：只读边界与受影响端点=空与提案声明一致；`words` 字段名勘误（任务书 `word` 笔误）对齐表列/实体，采纳。

## 3. 派发

- B-Impl 小实现任务书：`pm/requirements/2026-08-30/sensitive-words-list-implementation-task.md`（实体/VO/端点 + 契约测试 + schema 文档与源契约文档同步）。
- 快照衔接：实现合入后 PM 验收批次微同步 74→**75**，随后派发 F-Impl 第二批（管理端敏感词管理页，依赖 list 端点 id 可发现性）。

## 4. 关联

- F-Impl 第一批任务书（同批 PR #106，执行中）· A8-P3-BE 回执 PR #97 §6.4 · 签署 PR #100 §3（观察项 4 即本提案动因）
- 决策人：协调 PM，2026-08-30
