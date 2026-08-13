# CoderClub 交接索引

本目录是 CoderClub 后端、前端与 PM 的跨项目交接入口。后端项目中的 API 定义和实现是运行时权威来源；经 PM 批准的 `api/coderclub-openapi.json` 是后续跨项目开发的权威契约快照，不等同于发布契约。

## 目录用途

| 路径 | 用途 |
| --- | --- |
| `api/` | PM 批准的开发契约快照；必须同步来源提交、源 SHA-256、快照提交、快照 SHA-256 和语义差异 |
| `designs/backend/` | 后端设计、接口影响分析和实现约束 |
| `designs/frontend/` | 前端设计、接口消费约束和交互影响分析 |
| `handoff/backend-to-frontend/` | 后端交给前端的版本、字段、行为和验证信息 |
| `handoff/frontend-to-backend/` | 前端交给后端的问题、请求和复现信息 |
| `proposals/backend/` | 后端提出的契约或跨项目变更提案 |
| `proposals/frontend/` | 前端提出的契约或跨项目变更提案 |
| `acceptance/backend/` | 后端验收记录、验证结果和已知限制 |
| `acceptance/frontend/` | 前端验收记录、验证结果和已知限制 |
| `pm/roadmap/` | 跨项目路线图和里程碑 |
| `pm/requirements/` | PM 确认的需求、范围和成功标准 |
| `pm/reviews/` | 评审结论、决策记录和风险处理 |
| `pm/reports/` | 阶段报告和交接摘要 |
| `status/` | 各角色当前状态与同步清单 |

## 文档日期目录约定

所有角色在交接仓库新建文档时，必须先在其所属目录下建立 `YYYY-MM-DD/` 日期目录（以文档创建日期为准，Asia/Shanghai），再写入文档；文件名不再带日期前缀，例如 `pm/reviews/2026-08-12/g1-03-close-acceptance.md`。豁免固定路径文件：`AGENTS.md`、`CLAUDE.md`、`CONTEXT.md`、`docs/INDEX.md`、`docs/adr/**`、`docs/agents/**`、`api/**`、`status/*.json`、`_template-*` 模板与 `.gitkeep`。

## 状态文件

- `status/pm.json`：PM 协调状态、当前分支、基线提交和远端推送授权状态。
- `status/backend.json`：后端项目状态、最近交接提交和待处理事项。
- `status/frontend.json`：前端项目状态、最近交接提交和待处理事项。
- `status/sync-manifest.json`：后端与前端的同步关系、契约引用和发布状态。`finalReleaseStatus` 只能在 PM 明确授权后更新；未授权时不得改写。

状态文件只描述可追溯元数据，不替代业务代码、测试或运行时权威 API。`apiContractCommit` 指向开发契约快照提交；`finalReleaseStatus` 仍独立受 PM 控制。提交哈希为空时表示该角色尚未提供可交接提交。

## 提交哈希交接方式

每次交接都记录来源仓库、分支、完整提交哈希、目标路径、变更摘要和验证命令。开发契约快照还必须记录源 SHA-256、快照 SHA-256 和语义差异。接收方先在对应项目运行 `git show <commit-hash>`，再检查 `git diff <parent>..<commit-hash>` 和验证结果。

PM 合并跨项目结论时，在 `handoff/` 或 `acceptance/` 记录双方提交哈希，并同步更新相关 `status/*.json`。交接仓库本身的治理提交也使用 Git 提交哈希追踪，远端推送需要单独授权。

## compact 后恢复步骤

1. 回到本目录，先读取 `AGENTS.md`、`CLAUDE.md` 和本索引。
2. 执行 `git status --short`、`git log -5 --oneline --decorate`，确认当前工作区和基线提交。
3. 读取 `status/pm.json`、`status/backend.json`、`status/frontend.json` 和 `status/sync-manifest.json`。
4. 按状态文件中的来源项目、分支和提交哈希，用 `git show` 核对交接内容，并核对开发契约快照的源/快照哈希。
5. 检查 `proposals/`、`handoff/`、`acceptance/` 和 `pm/reviews/` 中尚未关闭的事项，再继续工作。
6. 继续前确认写入范围；不得因上下文压缩而直接修改权威 API、另一项目或发布状态。
