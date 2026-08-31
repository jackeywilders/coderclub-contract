# 任务书：MessageVO 补 isRead 实现（B-Impl，排期登记）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：后端实现（B-Impl）
> 提案（已 PM 确认）：`proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136，R2 main）；PM 决策：`pm/reviews/2026-08-31/messagevo-isread-item-decision.md`（PR #135，立项）+ `messagevo-isread-item-proposal-decision.md`（确认，本批）
> **排期状态：并入后续批次派发**（阶段四 interview 排期或空档小批）——本任务书为排期登记与执行口径，开工时机随批次；不单独占排期

## 1. 任务明细

按提案 §3/§4 逐条执行：

1. **枚举**：新增 `com.jackey.circle.domain.enums.MessageIsReadEnum`——`READ(1,"已读")` / `UNREAD(2,"未读")`，`getCode()` 标注 Jackson **`@JsonValue`**（HTTP 序列化输出数字 1/2，杜绝默认枚举名）；静态 `of(Integer)` 工厂（null 安全，null → null）。
2. **BO**：`MessageBO` 补 `isRead`（enum）——domain `page()` 组装循环 `bo.setIsRead(MessageIsReadEnum.of(e.getIsRead()))` 一行透传（**组装先于 `markReadByIds`，天然取读前原值**，置读时机零改动）。
3. **VO**：`MessageVO` 补 `isRead`（enum）——与 BO 同名同型，MapStruct-Plus `@AutoMapper` 自动映射零配置。
4. **entity / DTO 不动**：`ShareMessageEntity.isRead`（Integer）与 `MessagePageQueryDTO.isRead`（请求筛选 Integer）保持现状（infra 不反向依赖 domain；请求侧避免 enum 反序列化耦合）。
5. **契约测试（判别性）**：既有 `getMessages_返回分页与格式化时间` 补断言——mock BO `setIsRead(UNREAD)` → `$.data.list[0].isRead` **= 2（数字）**（漏透传/误值/@JsonValue 失效均必失败）。
6. **domain 单测（置读前时序）**：`ShareMessageDomainServiceImplTest` 补断言——mock infra 返回 `is_read=2` 行 → `page()` 返回 `BO.isRead=UNREAD`（原值），且 `markReadByIds` 在组装后被调用。
7. **源契约文档**：`docs/api/coderclub-openapi.json` 的 `MessageVO` schema 补 `isRead`（type integer/int32，description 注明读取时点语义）+ `getMessages` 200 example 补 `"isRead": 2`；**75 路径不变**；回执登记 LF SHA before/after（before = `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90`）。

## 2. 交付与回执（规则 9）

1. 分支 `feat/backend-message-isread`（或等价命名）→ CoderClub PR；CI 全绿后由用户/B-Review 合入（仓库惯例）。
2. 回执双轨：`handoff/backend-to-frontend/` 按创建日期目录（Markdown + `*-summary.json` 模板字段齐全，**含 `receiptCommitSha`**），完成通知四字段。
3. 快照衔接：实现合入后 PM 验收批次微同步（`MessageVO.isRead` 采纳，75 路径不变）。

## 3. 约束

- 仅补 `MessageVO.isRead` 透传 + 枚举；不触碰其他端点/字段/鉴权/错误码；**置读时机（返回后按页置已读）零改动**；`unRead` 计数与 `isRead=2` 筛选语义不变。
- 前端代码零改动（消息页渲染属后续 F-Impl 批次）；不改 `api/` 快照与 `status/sync-manifest.json`（PM 验收后微同步）。
- 规则 8 敏感信息占位符与 Conventional Commits 照常。

## 4. 关联

- 立项决策 PR #135 · 提案 PR #136 · 确认决策（本批）· F-Review openItem `messagevo-item-isread` · 第一批回执 PR #112 §6 待确认项 1
