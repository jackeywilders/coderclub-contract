# PM 决策：MessageVO 补 isRead 契约提案确认（D2）

> 决策角色：协调 PM
> 决策日期：2026-08-31
> 提案：`proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136，已合入 main，MCP 核验）
> 来源：PM 立项决策 `pm/reviews/2026-08-31/messagevo-isread-item-decision.md`（PR #135）
> 状态：**提案确认通过；排期登记——并入后续批次派发（不单独占排期）**

## 1. 决策结果

| 项 | 内容 | 决策 |
| --- | --- | --- |
| 契约 | `MessageVO.isRead`（Integer 语义值 1=已读 / 2=未读，JSON 输出数字），返回**读取时点（置已读前）状态**；`getMessages` 75 路径不变，schema + example 登记（example=2） | ✅ 按提案 |
| 实现 | `MessageIsReadEnum`（domain 层，`@JsonValue` 数字序列化）；BO/VO 用 enum（MapStruct 自动映射）；entity/DTO 保持 Integer；domain 组装 `of(e.getIsRead())` 一行透传（先于 `markReadByIds`，天然读前原值，置读时机零改动） | ✅ 按提案 |
| 验收 | 契约测试判别断言（UNREAD → JSON 2，双轴锚定透传 + 序列化）+ domain 置读前时序断言；源文档 LF SHA before/after 登记 | ✅ 按提案 |
| 排期 | 并入后续批次（阶段四 interview 排期或空档小批），不单独占排期 | ✅ 按提案（任务书已备，随批次派发） |

## 2. 决策理由

1. 提案与 PM 立项决策（PR #135）语义口径**完全一致**（读取时点状态、不改置读时机、向后兼容 fromId 先例同构）——无新增决策分歧。
2. 实现口径细化合理：enum 层隔离（domain 用 enum + `@JsonValue` 保证 JSON 数字输出；entity/DTO 保持 Integer 避免 infra 反向依赖 domain）与既有架构分层一致；组装先于置读的时序设计天然满足「读前原值」。
3. 验收口径双轴锚定（判别断言防漏透传/误值/序列化失效 + 时序断言锚定置读前状态）——与 MOMENT-ITEM-FROMID 判别性断言先例同质，可验收。

## 3. 排期登记

- **任务书已备**：`pm/requirements/2026-08-31/messagevo-isread-implementation-task.md`（B-Impl），随后续批次派发（阶段四 interview 排期或空档小批）。
- **后续链**：派发 → 实现 + 回执 → B-Review 签署 → PM 验收 + 快照微同步（`MessageVO.isRead` 采纳，75 路径不变）→ F-Impl 消息页条目渲染（未读高亮/圆点，随前端后续批次）。

## 4. 关联

- 立项决策 PR #135 · 提案 PR #136 · F-Review openItem `messagevo-item-isread` · 第一批回执 PR #112 §6 待确认项 1
- 决策人：协调 PM，2026-08-31
