# M4-06 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-17
> **任务：** M4-06 装饰字段（pageNo/pageSize）运行时移除
> **任务书：** `pm/requirements/2026-08-16/m4-06-implementation-task.md`（方案确认）；原任务书 `pm/requirements/2026-08-13/m4-06-decorative-fields-task.md`（关闭条件）
> **提案与 PM 决策：** `proposals/backend/2026-08-16/m4-06-decorative-fields-proposal.md` §7（**案二：运行时移除**，2026-08-16）
> **执行回执：** `handoff/backend-to-frontend/2026-08-16/m4-06-decorative-fields-report.md`（回执提交 `494e862`，**已合入 main**：PR #11，main `f4e96be`，R2 生效）
> **实施提交（私有后端仓库，人链核验）：** `ae2bb7e`（feat(subject): M4-06 运行时移除列表项分页装饰字段 pageNo/pageSize）——本次验收复验：`git cat-file -e ae2bb7e^{commit}` 存在，提交消息与任务一致
> **复核签署：** 后端评审（B-Review），2026-08-16（回执 §9；工作底稿 `designs/backend/2026-08-16/m4-06-decorative-fields-review-workpaper.md`）
> **验收结论：** ✅ **通过，M4-06 关闭；M4 全部六任务验收完成**

## 关闭条件逐项核验（原任务书 §4 关闭条件 1-4）

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | 提案获 PM 批准（含选定方案与决策记录） | 提案 §7 协调 PM 决策：案二运行时移除；任务书 §2 决策摘要；`status/pm.json` `m4SixDecision` 同记录 | ✅ |
| 2 | 实施提交存在且测试全绿（含 `SubjectContractTest` 45/45 回归与既有测试） | 实施提交 `ae2bb7e`（本次复验存在）；新增视图序列化测试 `SubjectInfoViewDtoSerializationTest` 2/2；全量 `mvn test` 全模块 BUILD SUCCESS——subject-app-controller 77/77（含 `SubjectContractTest` 49/49） | ✅ |
| 3 | 快照/基线一致（如涉契约声明：全链核对） | 案二不涉快照同步；后端 OpenAPI 源 SHA `7576e28a…` 未变（43/43）、交接快照 `9a97c055…` 未变、`sync-manifest.json` 未变（回执 §6，git status 确认） | ✅ |
| 4 | 回执含提案编号、PM 确认记录、提交哈希与测试输出，后端评审复核签署 | 回执 §1 来源与提交哈希、§2 提案与 PM 确认、§4 测试命令与原始输出、§9 复核签署（规范/规格双轴 + 独立重跑 77/77 + 契约核验） | ✅ |

> 备注：任务书实施要求 2 中 `SubjectContractTest` 45/45 为 G1-04 前基线；G1-04 后已扩展至 49/49，回执 §4.2 已说明无回归（断言改为适配 `SubjectInfoViewDTO` 的 list 元素）。

## 关键核验

- **运行时移除已生效**：4 个读端点响应改用 `SubjectInfoViewDTO`（不继承 `PageInfo`），序列化不再输出列表项 `pageNo`/`pageSize`；请求体 `SubjectInfoDTO` 分页参数能力保留。
- **真实响应复核（回执 §5）**：Nacos dev 环境 `POST /subject/getSubjectPage`，`data.list` 元素 JSON 不含 `pageNo`/`pageSize`；外壳分页仍生效（`pageNo=1`、`pageSize=10`、`total=28`、`listSize=10`）。
- **契约未变**：未改任何字段/路径/方法；`api/` 快照与 `sync-manifest.json` 均未变更（回执 §8 声明 + git status 确认）。
- **前端零破坏**：前端未消费列表项该两字段（提案 §2.3 已核实），移除零影响。
- **远程优先核验（新协议）**：回执 R2 已合入 `main`（`git merge-base --is-ancestor 53d9102 origin/main` ✓）；实施提交经人链 + 本次复验存在。

## 已知限制（验收知悉，不阻塞关闭）

1. 仅覆盖 `SubjectInfoViewDTO` 所列业务字段；后续字段增改需同步视图 DTO。
2. 请求侧分页装饰字段保留（预期行为：请求参数能力保留）。

## 备注

- 无阻塞项；关闭条件 1-4 全部满足，且第 2 条实测测试数高于基线要求。
- **M4 全部六任务（01-06）验收关闭**；`status/pm.json` 更新：`state` → `gate0-1-m4-all-accepted`（受控枚举，表示 M4 全关），`m4AcceptanceReports` 增补 m4-06。
- **下一步（Gate 4）**：M4 全关后进入 Gate 4 发布门禁。`releaseStatus`/`finalReleaseStatus` 变更**须用户明确授权**；发布前按敏感扫描规则再全历史复验（`releaseReady` 保持 `false`）。
