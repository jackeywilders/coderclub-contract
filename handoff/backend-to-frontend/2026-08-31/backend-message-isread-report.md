# 回执：MessageVO 补 isRead 实现（B-Impl，D2）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-31（Asia/Shanghai）
> **任务书：** `pm/requirements/2026-08-31/messagevo-isread-implementation-task.md`（第二批四线之一）
> **提案：** `proposals/backend/2026-08-31/messagevo-isread-item-proposal.md`（PR #136，R2 main）；PM 决策（PR #135 立项 + 确认决策）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-31-message-isread-design.md`（2816d4d）、`docs/superpowers/plans/2026-08-31-message-isread.md`（228d846，随本 PR 合入）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-message-isread`（基于 `86a09e7`） |
| 实现头 | `f6c23a0`（6 提交：spec + plan + 枚举/透传 + openapi + 最终审查修复波） |
| PR | **#21**（feat/backend-message-isread → main） |
| CI | build-and-test + sensitive-scan（head `f6c23a0`，双绿核验后转人工合入） |
| 合入状态 | **R1 达成**；R2 待人工合入（用户/B-Review 在 CI 全绿后执行） |

## 2. 任务明细（对照任务书 §1 七项）

1. **枚举** ✅：新增 `MessageIsReadEnum`（`READ(1,"已读")`/`UNREAD(2,"未读")`；`getCode()` 标注 **`@JsonValue`**——HTTP 序列化输出数字 1/2 杜绝枚举名；静态 `of(Integer)` null 安全：null→null、1→READ、其余→UNREAD）。
2. **BO** ✅：`MessageBO` 补 `isRead`（enum）；`ShareMessageDomainServiceImpl.page()` 逐行组装（line 73）`bo.setIsRead(MessageIsReadEnum.of(e.getIsRead()))` 一行透传——**组装先于 `markReadByIds`**，天然取读前原值；置读时机零改动。
3. **VO** ✅：`MessageVO` 补 `isRead`（enum）——与 BO 同名同型，MapStruct-Plus 自动映射零配置。
4. **entity / DTO 不动** ✅：`ShareMessageEntity.isRead`（Integer）、`MessagePageQueryDTO.isRead`（请求筛选 Integer）保持现状。
5. **契约测试** ✅：`CircleContractTest.getMessages_返回分页与格式化时间` 补判别断言——mock BO `setIsRead(UNREAD)` → `$.data.list[0].isRead` = **2（数字）**（漏透传/误值/@JsonValue 失效均必失败）；CircleContractTest 23/23。
6. **domain 单测** ✅：`ShareMessageDomainServiceImplTest` 补时序用例——mock infra `is_read=2` → `page()` 返回 `BO.isRead=UNREAD`；**最终审查修复**：时序断言改 `InOrder`（`pageByToId` 先于 `markReadByIds`，锚定组装先于置读）；8/8 全绿。
7. **源契约文档** ✅：`MessageVO` schema 补 `isRead`（integer/int32，description 注明读取时点语义，example 2）+ `getMessages` 200 example `"isRead": 2`；**75 路径不变**；LF SHA `26AEC009C4A823629DCC1D6EB5984773791BC3380407F846AAA7D4308F12CC90 → 57C2D6EE12D071CD6799718D7F772DAE10587C5FD7B876443CDAB06CF29E91D4`。

## 3. 测试证据

- 全仓 `mvn install -DskipTests -q` + `mvn test` 绿（exit 0）；CircleContractTest 23/23（判别 isRead=2）+ ShareMessageDomainServiceImplTest 8/8（时序 InOrder）。
- 审查链：brainstorming（设计获批）→ SDD 执行（Task1/2 子代理 + 任务审查 clean）→ 全分支最终审查（修完再合：时序断言 InOrder 加固 + MessageBO 类注释）→ 定向复审 **2/2 ADDRESSED**。

## 4. 边界遵守声明（任务书 §3）

- 仅补 `MessageVO.isRead` 透传 + 枚举；不触碰其他端点/字段/鉴权/错误码；**置读时机零改动**；`unRead` 计数与 `isRead=2` 筛选语义不变。
- 前端零改动（消息页渲染属后续 F-Impl 批次）；未改 `api/` 快照与 `status/`（PM 验收后微同步）；规则 8；Conventional Commits。

## 5. 已知限制与延后项

1. **`of()` 值域外值静默降级 UNREAD**（Minor）：0/3/负值一律映射 UNREAD，不抛错不留痕——规格明确"保持简单，DB 值域 1/2"，注释已记录该约定；若需脏值可见性可后续加 warn 日志（延后）。
2. **`desc` 字段无输出路径**（Minor）：`getDesc()` 未被序列化使用（`@JsonValue` 接管），仅语义元数据——保留作文档价值（延后）。
3. **同类裸 verify 用例存在**（范围外观察）：`getMessages_结构化展开_批量昵称_返回后按页内置已读` 仍用裸 verify——时序契约已由本批 InOrder 用例覆盖，非阻塞。

## 6. 后续链

1. B-Review 复核签署 → PM 验收 → **快照微同步**（`MessageVO.isRead` 采纳，75 路径不变）→ F-Impl 消息页条目渲染（未读高亮/圆点，随前端后续批次）。
2. 合入提醒：PR #21 CI 双绿，**合入由人工（用户/B-Review）在 GitHub 执行**。
3. 同批衔接：subject-search-meilisearch / redis-integration / r2-backup 三线并行推进中。

---
- 回执角色：后端实现（B-Impl），2026-08-31
