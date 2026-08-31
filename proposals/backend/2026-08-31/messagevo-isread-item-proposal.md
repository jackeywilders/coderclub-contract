# Proposal：MessageVO 补条目级 isRead（D2，读取时点状态）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-31
> **来源：** PM 决策 `pm/reviews/2026-08-31/messagevo-isread-item-decision.md`（PR #135，已立项）——源自 A8-P3-FE 第一批回执 §6 待确认项 1（`frontend-circle-report.md`），F-Review 评估（openItem `messagevo-item-isread`）
> **背景：** grill 共识（2026-08-31，用户逐项确认 Q1-Q4）——`MessageVO` 缺条目级 `isRead` 字段，消息列表「全部」tab 无法区分已读/未读（未读高亮/圆点缺失）；决策口径 = 补 `isRead`（1=已读 2=未读），返回**读取时点（置已读前）状态**，与「读取即已读」兼容（不改置读时机）
> **状态：** 待 PM 确认

## 1. 背景与问题

- 消息分页 `POST /circle/share/message/getMessages` 现有响应 VO `MessageVO` 无条目级 `isRead`，消息列表仅能靠「全部/未读」筛选 tab 表达状态，「全部」tab 无法区分已读/未读——未读高亮/圆点等常见体验缺口（决策理由 1）。
- 数据侧已具备状态字段：`share_message.is_read`（1=已读 2=未读，`ShareMessageEntity.isRead`），`MessagePageQueryDTO.isRead` 筛选（1/2/null 查全部）语义一致；仅响应 VO/BO 未透传。

## 2. 契约变更

| 项 | 定义 |
| --- | --- |
| 端点 | `POST /circle/share/message/getMessages`（既有端点，**75 路径不变**，schema 字段级） |
| VO 字段 | `MessageVO.isRead` — **Integer 语义值 1=已读 / 2=未读**（JSON 序列化输出数字，非枚举名） |
| 返回语义 | **读取时点（置已读前）状态**：查询返回 `is_read` 原值 → 响应携带原值 → 返回后按页内 ids 批量置已读（既有 `markReadByIds` 逻辑零改动，空页跳过）。效果：进入消息页本次请求未读条目 `isRead=2`（前端高亮/圆点），刷新/翻页后 `isRead=1`——与「读取即已读」「返回后未读数归零」完全兼容 |
| schema | `MessageVO.properties.isRead`：`{"type":"integer","format":"int32","description":"是否已读：1=已读 2=未读；读取时点（置已读前）状态——返回后按页内 ids 置已读，本次响应反映读前原值，与「读取即已读」兼容","example":2}` |
| example | `getMessages` 200 `data.list[0]` 补 `"isRead": 2`（未读示例，直观表达读前状态语义） |

响应示例（规则 8：语义化样本）：

```jsonc
// POST /circle/share/message/getMessages → data.list[0]（本次请求：读前未读 → 高亮/圆点；刷新后 isRead=1）
{
  "id": 10, "msgType": "COMMENT", "targetId": 2, "msg": "评论了你的动态",
  "fromId": "1003", "fromNickName": "张三", "createdTime": "2026-08-30 12:00:00",
  "isRead": 2
}
```

## 3. 实现口径（B-Impl 执行面，供派发参考）

1. **枚举**：新增 `com.jackey.circle.domain.enums.MessageIsReadEnum` — `READ(1,"已读")` / `UNREAD(2,"未读")`，`getCode()` 标注 **Jackson `@JsonValue`**（HTTP 序列化输出数字 1/2，杜绝默认枚举名字符串；circle 服务无 fastjson2-extension，走 Spring Boot 默认 Jackson），静态 `of(Integer)` 工厂（null 安全，null → null）。
2. **BO**：`MessageBO` 补 `isRead`（enum）——domain `page()` 组装循环 `bo.setIsRead(MessageIsReadEnum.of(e.getIsRead()))` 一行透传（**组装先于 `markReadByIds`，天然取读前原值**，置读时机零改动）。
3. **VO**：`MessageVO` 补 `isRead`（enum）——与 BO 同名同型，MapStruct-Plus `@AutoMapper` 自动映射零配置。
4. **entity / DTO 不动**：`ShareMessageEntity.isRead`（Integer 列映射）与 `MessagePageQueryDTO.isRead`（请求筛选 Integer）保持现状——infra 不反向依赖 domain；请求侧避免 enum 反序列化耦合。

## 4. 契约测试与验收口径

| # | 项 | 断言 |
| --- | --- | --- |
| 1 | **契约测试（controller 层，判别性）** | 既有 `getMessages_返回分页与格式化时间` 用例补断言：mock BO `setIsRead(UNREAD)` → `$.data.list[0].isRead` **= 2（数字）**——若漏透传（null）、误填已读（1）或 @JsonValue 失效（输出枚举名）断言必失败，双轴锚定透传与序列化 |
| 2 | **domain 单测（置读前时序）** | `ShareMessageDomainServiceImplTest` 补断言：mock infra 返回 `is_read=2` 行 → `page()` 返回 `BO.isRead=UNREAD`（原值），且 `markReadByIds` 在组装后被调用——锚定「读取时点（置已读前）状态」 |
| 3 | 回归 | circle 契约既有用例 + domain 全量 + 全仓 mvn 绿；CI 双绿 |
| 4 | 源文档 | `docs/api/coderclub-openapi.json` schema + example 登记；**75 路径不变**；回执登记 LF SHA before/after |

## 5. 向后兼容说明

- **只读响应 VO 新增字段**（fromId 先例同构）：旧客户端忽略新字段不受影响；无鉴权/错误码/路径/请求侧变更。
- **置读时机零改动**：`getMessages`「返回后按页内置已读」行为、`unRead` 计数、`isRead=2` 未读 tab 筛选语义均不变；`isRead` 返回的仅是查询时点快照值。
- **未读 tab 边界**：`isRead=2` 筛选下条目全部未读，条目级标记无增量信息——前端可按 tab 语义简化渲染（不强制条目级高亮），本提案不涉及前端渲染（F-Impl 侧）。

## 6. 排期与后续链

- **排期**：**并入后续批次**（阶段四 interview 相关排期或 B-Impl/F-Impl 空档小批），**不单独占排期**（决策 §3）。
- **后续**：PM 确认 → 排期派发 B-Impl → 实现 + 回执 → B-Review 签署 → PM 验收 + 快照微同步（`MessageVO.isRead` 采纳，75 路径不变）→ F-Impl 消息页条目渲染（未读高亮/圆点）。
