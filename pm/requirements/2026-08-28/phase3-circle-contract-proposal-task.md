# 任务书：A8 阶段三社区域（circle）契约提案起草

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-28
> **执行角色：** 后端评审（B-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§7（circle 域细则：端点集/DFA 敏感词/评论树/消息拉取，WebSocket 后置）
> **参考语义：** 参考项目（jc-club）circle 域实现（勘察记录）：share/circle/list、share/moment/save|getMoments|remove、share/comment/save|list|remove、share/message/unRead|getMessages、sensitive/words/save|remove；DFA 敏感词（WordContext/WordFilter Trie + 白名单）
> **状态：** A8 阶段二已闭环（state gate3-a8-phase2-accepted）；阶段三启动

## 1. 目标

起草 A8 阶段三社区域的批量契约提案（circle 域 C 端端点 + 敏感词管理端点），供 PM 确认后转 B-Impl 实现。表结构已有（share_circle/share_moment/share_comment_reply/share_message + sensitive_words，云端核验与 schema 一致），**无新表预期**（差异分析确认）；消息通知采用**落库 + 拉取**形态（Q6 决策 A，WebSocket 后置不做）。

## 2. 端点清单（语义基准，按差异分析定稿）

### C 端（前缀 /circle）

| # | 端点 | 语义要点 |
| --- | --- | --- |
| 1 | `GET /circle/share/circle/list` | 圈子树（parent_id=-1 大类 + 子圈）；Caffeine 短缓存可选 |
| 2 | `POST /circle/share/moment/save` | 发布动态：content（**敏感词校验**：黑名单命中拒绝、白名单跳过）+ pic_urls（OSS URL JSON 数组字符串）→ moment_id |
| 3 | `POST /circle/share/moment/getMoments` | 动态分页列表：批量用户昵称头像（Feign `list-by-identifiers`）、评论数回显、无限加载分页 |
| 4 | `POST /circle/share/moment/remove` | 删除动态（本人）：级联软删评论 + 回减 |
| 5 | `POST /circle/share/comment/save` | 评论/回复（reply_type 1 评论 2 回复；parent_id 语义）；保存后**消息落库**（share_message：to 动态作者/被回复人，msgType COMMENT/COMMENT_REPLY + targetId） |
| 6 | `POST /circle/share/comment/list` | 某动态全部评论（树形返回） |
| 7 | `POST /circle/share/comment/remove` | 删除评论（本人/作者）：子树批量软删 + 计数回减 |
| 8 | `GET|POST /circle/share/message/unRead` / `getMessages` | 未读/消息列表分页（**读取即已读**） |

### 管理（前缀 /circle/sensitive）

| # | 端点 | 语义要点 |
| --- | --- | --- |
| 9 | `POST /circle/sensitive/words/save` | 敏感词维护（type 1 黑名单 2 白名单） |
| 10 | `POST /circle/sensitive/words/remove` | 删除敏感词 |

（端点数与拆分以差异分析为准；WebSocket 消息推送**不在本阶段**。）

## 3. 任务 1：差异分析（交付物：随 proposal 或 designs 文档）

对照参考实现与表结构（已有：share_circle 4 表 + sensitive_words；OAuth 已具 `oss/upload`）：

1. 圈子树结构（parent_id=-1 语义）与 Caffeine 缓存取舍
2. 动态列表的昵称/头像组装（Feign 复用 `auth list-by-identifiers`——created_by 存 userName 还是 loginId？与 practice 排行先例对齐决策）
3. 评论树：share_comment_reply 复合主键（id,parent_id）与 TreeUtils 子树删除、reply_count 计数一致性的实现方案
4. 消息：share_message content JSON（msgType/targetId）语义；读取即已读的并发语义
5. 敏感词：WordFilter DFA 实现形态（加载时机/白名单/skip 可选）、管理端点鉴权（管理角色？）
6. 归属/越权：动态/评论删除的本人/作者校验（对齐 practice requireOwnedPractice 模式）
7. 字符集：share 系表 utf8mb4（云端核验）无迁移；确认
8. **categoryId 一级过滤语义确认（openFinding 随附）**：门户首页分类筛选是否需后端支持一级递归过滤——若需，随本阶段一并评估（否则维持现状，另案关闭）

## 4. 任务 2：契约提案（proposals/backend/2026-08-28/phase3-circle-endpoints-proposal.md）

- 批量提案全部 circle 端点（预计 8-10 个），语义基准 = 上表 + 差异分析结论。
- 风格对齐现有提案范式（`ResponseResult`、DTO PageQuery、description 中文）；鉴权：C 端 `@SaCheckLogin`（门户登录墙）；敏感词管理端点鉴权按差异分析第 5 点（建议管理角色，proposal 明示）。
- 不修改既有端点；请求/响应示例语义化（规则 8）；internal 标注（如有）。
- 优先级标注（如 P0 圈子/动态/评论核心链 / P1 消息与敏感词管理）。

## 5. 交付与回执（规则 9）

1. 差异分析 + 提案落 `designs/backend/2026-08-28/` + `proposals/backend/2026-08-28/`，经 `codex/backend-contract` PR 合入交接仓库 main。
2. 完成通知带四字段告知 PM；PM 确认（含 categoryId 语义、鉴权、DDL 差异决策）后派发 B-Impl 实现任务书。
3. 冲突点明示交 PM。

## 6. 验收标准

- [ ] 差异分析 8 要点全部三选一/结论明确（含 categoryId 语义结论），DDL 变更清单明确（预期无）
- [ ] 批量提案端点完整（请求/响应/鉴权/错误码/示例），风格对齐，无敏感信息
- [ ] 消息落库拉取形态（无 WebSocket 依赖）；敏感词 DFA 形态明确
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改既有端点
- [ ] 合入 main + 通知四字段

## 7. 关联

- 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §7（PR #79）
- openFinding：`categoryId-primary-filter-semantics`（确认项随附）
- 后续：PM 确认 → B-Impl 实现（含新模块 `coder-club-circle` 四层 + Feign 复用）→ 回执 → B-Review 签署 → PM 验收 → 快照全链同步 → 前端阶段三任务书（F-Impl：鸡圈页）