# Claude Code 工作边界

Claude Code 在 CoderClub 项目中只能实现已经确认的业务代码、业务测试和必要的本地验证，不负责制定跨项目契约，也不负责发布交接仓库状态。

## 契约问题处理

- 后端发现接口问题或需要接口变更时，写入交接仓库的 `proposals/backend/`。
- 前端发现接口问题或需要接口变更时，写入交接仓库的 `proposals/frontend/`。
- 提案应说明现状、问题、建议方案、兼容性影响、来源提交哈希和验证方式。
- Claude Code 不能直接修改权威 API，也不能通过修改 `api/` 或 `status/sync-manifest.json` 绕过提案、评审和授权流程。
- 未获确认的契约提案不得作为前端或后端的既定接口实现。

## 写入边界

在后端工作时，只修改 `G:/Dev/backend/Club/CoderClub/**` 中的业务代码和测试；在前端工作时，只修改 `G:/Dev/backend/Club/CoderClubFront/**` 中的业务代码和测试，并按 `AGENTS.md` 约定写入对应的提案、交接或验收记录。

Claude Code 不得修改另一项目，不得复制 OpenAPI 文件到交接仓库，不得修改交接仓库治理文件，不得推送远端。需要跨项目决策时，将信息交给 PM Codex 协调。
