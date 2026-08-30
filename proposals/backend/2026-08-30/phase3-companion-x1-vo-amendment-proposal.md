# Proposal：X1 消费侧 VO 契约增补（IdentifierUserItemVO 新增 id 字段）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-30
> **任务书：** `pm/requirements/2026-08-30/phase3-companion-proposals-task.md`（PR #99，提交 `c3c3c958`）任务 1
> **背景：** A8-P3-BE 回执 openFinding C1（`handoff/backend-to-frontend/2026-08-30/backend-a8p3-circle-domain-report.md` §6.1，PR #97）；复核签署 `acceptance/backend/2026-08-30/a8p3-circle-domain-review-signoff.md` §3.1（PR #100）
> **状态：** 待 PM 确认

## 1. 背景与问题（C1 事实链）

- **X1 查询层已就位**（A8-P3 实施 `d9eb64f`，已合入 CoderClub main `583b4bb`）：`POST /auth/user/list-by-identifiers` 纯数字标识同时按 `id IN` 匹配（两次查询并集按 id 去重），向后兼容。
- **但响应 VO 不含 id**：`IdentifierUserItemVO` 仅 `{userName, nickName, avatar}`——消费方按返回条目的 `userName` 建键，而 circle/practice 的查找键是 `created_by` 等 **loginId 数字串** → 键空间不匹配 → 数字标识解析**降级为标识串**（云端实测 `nickName="1"/"9"`；种子数据 userName 型 created_by 正常解析）。
- **影响面**：practice 综合练习榜（A8-P2 起）、circle 动态列表/评论树/消息（A8-P3）的昵称显示；"修复 practice 排行昵称"原声明已由 B-Impl 在 PR #15 如实撤回，本提案补齐闭环。

## 2. 契约变更

| 项 | 定义 |
| --- | --- |
| 字段 | `IdentifierUserItemVO` 新增 **`id: Long`**（auth_user 表主键） |
| OpenAPI | `/auth/user/list-by-identifiers` 响应 schema `IdentifierUserItemVO` 增 `id`，标 **required**（auth 对每个命中用户恒返回主键，不可能为 null；响应增字段对既有消费方向后兼容） |
| 同构约定 | VO 副本共 **4 处**同步增字段：auth 源（`com.jackey.auth.app.entity`）+ circle-api / practice-api / subject-api 三份消费副本（副本 javadoc 明示"跨服务字段一致"约定，保持同构） |
| 鉴权/路径/其余字段 | 零变化 |

## 3. 消费方建键改动（双键别名，grilling 定稿）

- `AuthUserDirectory`（circle，`domain/support/AuthUserDirectory.java:44`）与 `PracticeDetailDomainServiceImpl.fetchUserMap`（practice，`:509`）在 map 构建循环中**各 +1 行**：`map.putIfAbsent(String.valueOf(u.getId()), u)`（id 键），保留既有 `putIfAbsent(u.getUserName(), u)`（userName 键）。
- **查找侧零改动**：仍按 `created_by` 等标识串 `get`——数字串命中 id 键、userName 型数据命中 userName 键，调用方无需关心数据属于哪个键空间（混合存量/增量数据的生产安全解）。
- subject contribute 的 nickMap（`SubjectController`）**不在本提案范围**（任务书点名 circle/practice）：其 userName 键对 userName 型数据继续工作，见 §5 后续建议。

## 4. 验收口径（任务书指定）

1. **practice 排行昵称修复**：数字 loginId 场景（`practice_info.created_by` 为 loginId 串）返回真实 nickName——云端验证断言排行条目 `nickName` 非数字串（A8-P2 已知限制就此闭环）。
2. **circle 三处生效**：动态列表/评论树/消息的 `fromNickName`/`nickName` 对数字标识返回真实昵称。
3. **测试**：auth 契约测试 VO 结构回归（新增 id 断言）；circle/practice 消费方契约测试 mock 数据补 `id` 字段；401 与 Feign 失败降级路径（标识串兜底）零回归。

## 5. 已知限制与后续建议

- **键碰撞边界**：理论上某用户 userName 恰等于另一用户 id 数字串时，双键下 `putIfAbsent` 以 id 键优先，存在显示错昵称可能——当前量级概率可忽略，如实登记。
- **[建议后续]** subject contribute nickMap 同款双键改造（约一行）：当前存量 `subject_info.created_by` 为 userName 型不触发；将来出现数字 loginId 型数据（如登录用户投稿落 loginId）前落地即可，交 PM 排期。
- **范围外**：X1 查询层（已就位不动）、其他端点、auth `/auth/user/info` 既有契约。

## 6. 待 PM 确认项

| # | 项 | 建议 | 需 PM 确认 |
| --- | --- | --- | --- |
| V1 | VO 新增 `id`（required）+ 4 副本同构 | 按本提案 | ✅ |
| V2 | 消费方双键别名 | circle/practice 各 +1 行，查找侧零改动 | ✅ |
| V3 | 验收口径 | §4（practice 排行修复为验收项，任务书指定） | ✅ |
| V4 | contribute 双键改造 | 列后续建议，不随本提案 | ✅ 知悉 |

## 7. 约束遵守声明

- 仅上述契约增补（响应增字段，向后兼容）+ 消费方建键各一行；**未改既有端点的路径/方法/鉴权/既有字段语义**；未动 `api/` 快照与 `sync-manifest`（PM 验收后随快照全链同步登记）；未改任何运行时源（本提案为文档，实现由 B-Impl 按本提案执行）。
- 示例语义化（规则 8），无真实环境信息。

## 8. 关联与后续

- 任务书 PR #99 · A8-P3 提案 PR #94 · 回执 PR #97 · 签署 PR #100 · X1 查询层实施 CoderClub PR #15（merged `583b4bb`）
- 后续：PM 确认（V1-V4）→ B-Impl 小批次实现（可与阶段三验收批次同批或独立，PM 排期）→ 回执 → 签署 → 验收

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-30
