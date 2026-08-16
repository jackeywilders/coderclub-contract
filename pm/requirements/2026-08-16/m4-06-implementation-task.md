# M4-06 后端实施任务书：装饰字段运行时移除（已确认方案）

> **任务角色：** 后端实现（B-Impl）
> **批准角色：** 协调 PM
> **任务日期：** 2026-08-16
> **任务状态：** ✅ **已确认方案，可实施**（此前为"待执行"，须先提案后实施）
> **实施前置已满足：** 提案已提交并获 PM 确认（见下）

## 1. 引用链（执行前必读，按序）

| 文件 | 用途 |
| --- | --- |
| `pm/requirements/2026-08-13/m4-06-decorative-fields-task.md` | 原任务书（任务摘要、执行步骤、验收边界与关闭条件） |
| `proposals/backend/2026-08-16/m4-06-decorative-fields-proposal.md` | 提案（两案评估 + 影响面清单） |
| 提案 §7「协调 PM 决策」 | **PM 决策：选定案二（运行时移除）**，含实施要求 1-5 |
| `pm/requirements/2026-08-13/m4-task-design.md` §3/§4 | 设计规格与验收流程 |

## 2. PM 决策摘要（2026-08-16）

- **选定方案：案二（运行时移除）**——从运行时响应移除 `SubjectInfoDTO` 列表项的装饰性 `pageNo`/`pageSize`，契约快照保持现状（`api/coderclub-openapi.json` SHA `9a97c055…` 不变）。
- **决策依据**：装饰字段无分页语义（请求分页在 `SubjectPageQueryDTO`、结果分页在外壳 `PageResultSubjectInfo`，均已声明）；快照当前声明语义正确，运行时移除即达成一致，无需同步快照；前端不消费、测试无断言，零破坏。

## 3. 实施要求（后端实现执行，回执须逐项覆盖）

1. **后端改造**：`SubjectInfoDTO` 响应输出路径——列表项 JSON **不输出** `pageNo`/`pageSize`；请求体仍可承载分页参数（`SubjectInfoDTO` 作请求参数能力保留）。实现方式由后端实现自定（视图类型 / 序列化忽略继承字段等），但**不得改变已批准契约的字段/路径/方法**。
2. **测试**：`SubjectContractTest` 45/45 回归 + 全量 `mvn test`（subject 53 基线，含 M4-04 后新增用例）全绿，无 Failures/Errors。
3. **真实响应复核**：真实环境请求 `POST /subject/getSubjectPage`，确认 `data.list` 元素 JSON **不含** `pageNo`/`pageSize`，且请求体分页参数仍生效（原始请求/响应记录，脱敏）。
4. **契约核验**：`docs/api/coderclub-openapi.json`（后端侧，SHA `7576e28a…`）与交接仓库 `api/coderclub-openapi.json`（SHA `9a97c055…`）**均不变化**；`status/sync-manifest.json` 不变。
5. **敏感约束**：回执与提交消息不写真实环境信息（IP/端口/凭据，规则 8）；不改交接仓库 `api/` 快照与 `status/sync-manifest.json`。

## 4. 回执与验收流程

1. **回执文件**：`handoff/backend-to-frontend/<执行日期>/m4-06-decorative-fields-report.md`（目录按回执实际创建日期落位），必含：来源项目/分支/实施提交哈希/回执提交哈希；提案编号与 PM 确认记录；测试命令与原始输出（含 `SubjectContractTest` 回归）；真实响应复核记录；契约 SHA 核验结果；已知限制；声明（未改 `api/` 快照与 `sync-manifest.json`、未伪造输出）。
2. **复核**：回执经**后端评审**（B-Review）复核签署（工作底稿 `designs/backend/<日期>/m4-06-...-review-workpaper.md`）。
3. **验收**：签署后由**协调 PM** 复核关闭条件（原任务书 §4 关闭条件 1-4），写 `pm/reviews/<日期>/m4-06-close-acceptance.md` 并更新 `status/pm.json`。

## 5. 边界提醒

- 未经本任务书确认方案前不得实施（已确认，可直接实施）。
- 实施中若发现两案之外的新选项或影响超出提案评估范围：**停止实施**，补充提案，重新经 PM 确认。
- 快照同步（如涉契约声明）仅由 PM 执行；本任务案二不涉及。

- 批准角色：协调 PM
- 日期：2026-08-16
