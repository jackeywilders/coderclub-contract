# Claude Code 工作边界

> 定位说明（2026-08-16）：本文件原为 Claude Code 客户端的执行边界。当前实现层角色（后端实现/前端实现）的工具不限定为 Claude Code，通用协作边界以 `AGENTS.md` 为准；本文件在"执行层不得越界"的语义上继续适用。

Claude Code 在 CoderClub 项目中只能实现已经确认的业务代码、业务测试和必要的本地验证，不负责制定跨项目契约，也不负责发布交接仓库状态。

## 契约问题处理

- 后端发现接口问题或需要接口变更时，写入交接仓库的 `proposals/backend/`。
- 前端发现接口问题或需要接口变更时，写入交接仓库的 `proposals/frontend/`。
- 提案应说明现状、问题、建议方案、兼容性影响、来源提交哈希和验证方式。
- 后端实现在对应提案获得 PM 确认后，可以修改后端项目的运行时权威 API 源 `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`，并在实现提交中记录提案、源 SHA-256、验证结果和语义差异；不得修改 PM 批准的交接仓库 `api/` 开发契约快照。
- 未获确认的契约提案不得作为前端或后端的既定接口实现。

## 写入边界

在后端工作时，后端实现只修改 `G:/Dev/backend/Club/CoderClub/**` 中的业务代码、测试和已获 PM 确认的运行时 API 源；在前端工作时，前端实现只修改 `G:/Dev/backend/Club/CoderClubFront/**` 中的业务代码、测试和已确认的前端基线。后端评审、前端评审按交接仓库 `AGENTS.md` 约定写入对应的提案、交接或验收记录。

在交接仓库新建提案、交接、验收等文档时，必须先建立 `YYYY-MM-DD/` 日期目录再写入，文件名不带日期前缀；约定见 `AGENTS.md` 协作规则第 6 条。

Claude Code 不得修改另一项目，不得复制 OpenAPI 文件到交接仓库，不得修改交接仓库治理文件，不得直接推送 `main` 或强制推送远端（角色分支 push 并发起 PR 属日常协作，见 `AGENTS.md` 规则 5）。需要跨项目决策时，将信息交给协调 PM。

## Agent skills

本仓库使用以下工程技能配置：

- **Issue 跟踪：** 使用本地 Markdown，规则见 `docs/agents/issue-tracker.md`，Issue 放在 `.scratch/<feature>/`。
- **领域上下文：** 单上下文布局，先读取根目录 `CONTEXT.md`；架构决策记录位于 `docs/adr/`，规则见 `docs/agents/domain.md`。
- **分类标签：** `triage` 使用的标准标签见 `docs/agents/triage-labels.md`。

开始任务前先读取 `CONTEXT.md`、本文件和 `AGENTS.md`；涉及架构决策、契约变更或跨项目影响时，再读取相关 ADR、提案和交接记录。
