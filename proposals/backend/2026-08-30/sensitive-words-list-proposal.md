# Proposal：敏感词词库 list 端点契约（POST /circle/sensitive/words/list，管理端）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-30
> **任务书：** `pm/requirements/2026-08-30/sensitive-words-list-proposal-task.md`（PR #106，已合入 main）
> **背景：** grill 共识（2026-08-30，用户逐项确认）——阶段三前端全量 11 端点消费（含管理端敏感词管理页），remove 需词 `id` 而无任何 list/查询端点，id 不可经 API 发现、管理不可运营（A8-P3-BE 回执 §6.4 / B-Review 签署 §3 观察项 4 登记）；F-Impl 阶段三第一批任务书同批派发
> **状态：** 待 PM 确认

## 1. 背景与问题

- 现有敏感词契约仅 `save`/`remove` 两管理端点：remove 按 `id` 删除，但系统内**无任何端点可枚举词与 id**——管理端只能加词、删词须直查数据库，词库盘点/审计同样依赖直查（登记于 A8-P3-BE 回执 §6.4 与签署 §3 观察项 4）。
- 本提案增补**只读 list 端点**闭环管理链路：加词 → 列表（含 id）→ 删词，管理页可运营。

## 2. 契约变更

| 项 | 定义 |
| --- | --- |
| 端点 | `POST /circle/sensitive/words/list`（管理端，与既有 save/remove 同域同形态；74→**75** 路径） |
| 鉴权 | `@SaCheckRole("admin_user")`——与既有两管理端点对齐；403 由既有 `NotRoleException` 映射承接（circle X3 先例） |
| 请求 | **无请求体**（零过滤参数——YAGNI：词库量级小，管理页本地分组/搜索） |
| 响应 | `ResponseResult<List<SensitiveWordItemVO>>`：`{id: Long, words: String, type: Integer(1=黑名单 2=白名单), createdTime: string|null}`，排序 **`type ASC, id ASC`**（前端按 type 自行分组渲染） |
| schema | 新增 `SensitiveWordItemVO`；required = `id / words / type`（createdTime 可 null——存量行无值，见 §3） |
| 命名勘误 | 字段名 **`words`**（复数）——与表列/实体/save DTO 一致；任务书"word"为笔误，随提案勘误对齐 |
| 查询口径 | **全量列表**（grilling Q2 定稿；量级评估见 §4） |

响应示例（规则 8：语义化样本，词取自 schema 文档默认数据）：

```jsonc
// POST /circle/sensitive/words/list → data（type ASC + id ASC）
[
  { "id": 1, "words": "赌博", "type": 1, "createdTime": null },          // 存量行：时间为空
  { "id": 2, "words": "代开发票", "type": 1, "createdTime": null },
  { "id": 3, "words": "招聘", "type": 2, "createdTime": "2026-08-30 12:00:00" }  // 新增词：自动填充
]
```

## 3. DDL 变更登记（A1 模式，已执行）

任务书响应要求含 `createdTime`，但 `sensitive_words` 表原仅有 `id / words / type / is_deleted` 四列（无 created_time/created_by，实体同构核验）。经 grilling 评估由用户裁定补列并**已于云端 MySQL 执行**：

```sql
ALTER TABLE `sensitive_words`
  ADD COLUMN `created_time` datetime DEFAULT NULL COMMENT '创建时间' AFTER `type`;
```

| 项 | 说明 |
| --- | --- |
| 执行 | 用户（A1 模式：运行时 DDL 由用户/运维执行），2026-08-30，云端库 |
| 存量行 | `created_time = NULL`，前端如实展示空白（不回填假时间） |
| 新增词 | 由 MyBatis-Flex 既有 createdTime 自动填充机制落值——save 端点逻辑零改动（实体加字段即可，实现面） |
| 字符集 | 表 utf8mb4，datetime 列无字符集影响 |
| schema 文档 | `docs/database/schema/doc_jc-club-init.sql` 同步列变更——归 B-Impl 实现批 |
| created_by | **未补列**（grilling 评估：save 现状未落 created_by，历史数据无值；若需审计补全 = 两列 DDL + save 语义变更，另案专项） |

## 4. 量级评估与查询口径（任务书要求明示）

- **全量列表**（非分页）：词库量级天然小——种子数据数行，且 DFA 启动即全量驻内存，全量返回不构成新负担；即使增长至千级，全量 JSON 亦在几十 KB 量级。管理表格需要全量盘点与跨组（黑/白名单）操作，分页反而引入翻页状态与口径成本。
- 权衡记录：PageInfo 分页（对齐全仓口径）可接受但当前量级零收益——本提案按全量定稿，若词库量级增长至万级再评估分页（另案）。

## 5. 语义边界

- **只读**：不触碰词库缓存/DFA 重建（与 save/remove 的重建语义严格区分）；读路径独立，无写副作用。
- **受影响端点**：无（纯新增；save/remove 既有语义与契约零变化）。
- **范围外**：C 端任何端点；X6 圈子管理另案；`created_by` 审计补全另案（§3）。

## 6. 验收口径（B-Impl 实现参考）

1. `SensitiveWordsEntity` 增 `createdTime` 字段（自动填充生效）；新增 `SensitiveWordItemVO` + list 端点（`@SaCheckRole`）。
2. 契约测试：200 全量（断言排序 type ASC + id ASC 与字段面）/ 401 未登录 / 403 非管理员（真实拦截链）。
3. 数据语义：存量行 `createdTime=null` 如实返回；save 新词后 list 可见且带时间。
4. 源契约文档登记 75 路径 + 新 schema；快照同步由 PM 验收批次执行（74→75）。

## 7. 待 PM 确认项

| # | 项 | 建议 | 需 PM 确认 |
| --- | --- | --- | --- |
| L1 | 响应字段面 `{id, words, type, createdTime}` + **DDL 已由用户执行登记（A1，2026-08-30）** + created_by 另案 | 按本提案 | ✅ |
| L2 | 查询口径 = 全量列表（非分页），理由 §4 | 按本提案 | ✅ |
| L3 | 边界（只读不触重建 / save-remove 零变化 / 受影响端点无） | 按 §5 | ✅ 知悉 |

## 8. 约束遵守声明

- 仅新增上述 1 端点 + 1 schema；未改既有端点/字段/鉴权/错误码语义；未动 `api/` 快照与 `sync-manifest`（PM 验收后微同步 74→75）；未改运行时源（本提案为文档，DDL 已由用户执行并登记，代码实现由 B-Impl 按本提案执行）。
- 示例语义化（规则 8），无真实环境信息。

## 9. 关联与后续

- 任务书 PR #106 · F-Impl 第一批任务书（同批派发）· A8-P3-BE 回执 PR #97 §6.4 · 签署 PR #100 §3 · 配套签署 PR #104
- 后续：PM 确认（L1-L3）→ B-Impl 小实现（实体/VO/端点 + schema 文档同步）→ 回执 → B-Review 签署 → PM 验收 → 快照微同步 74→75 → F-Impl 第二批（管理端敏感词管理页）

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-30
