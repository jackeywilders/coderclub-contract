# 后端治理文件 CLAUDE.md 三处补强任务书（交后端评审/实现）

> **任务角色：** 后端评审（B-Review）/ 后端实现（B-Impl）
> **下发角色：** 协调 PM
> **日期：** 2026-08-18
> **来源：** 技能治理适配定案（`docs/agents/skills-integration.md`，PR #23 已合入）+ 后端治理全面检查
> **范围：** 后端代码仓库 `G:/Dev/backend/Club/CoderClub/CLAUDE.md` 三处补强（不涉及 Java 源码）

## 1. 背景

协调 PM 对后端治理文件全面检查后发现三处需对齐当前治理：

1. **写入边界缺技能产物目录**：后端已实际使用 `docs/superpowers/**`（19 份 spec/plan），但 `CLAUDE.md` 第 1 条负责范围未含该目录——治理未跟上使用事实；`skills-integration.md` 已定义其定位（实现层 spec/plan，契约变更仍走 proposal）。
2. **过时 worktree 路径**：第 2 条契约问题引用旧 `coderclub-contract-claude-backend` worktree，当前主远端已统一 GitHub、角色用 `codex/backend-contract` 分支——需修正。
3. **缺规则 9 回执双轨**：第 3 条批准后契约实现未要求按规则 9 提交双轨回执。

## 2. 待应用 diff（三处，均在后端 `CLAUDE.md`）

**① 第 1 条负责范围——补技能产物目录：**

```diff
-1. **负责范围**：负责 `G:/Dev/backend/Club/CoderClub/**` 的后端源代码、测试、实现提交和本地验证；不得修改前端项目或其他项目。
+1. **负责范围**：负责 `G:/Dev/backend/Club/CoderClub/**` 的后端源代码、测试、实现提交、本地验证，以及本仓库 `docs/superpowers/**`（工程技能 spec/plan 产物，定位见交接仓库 `docs/agents/skills-integration.md`）；不得修改前端项目或其他项目。
```

**② 第 2 条契约问题——修正过时 worktree 路径：**

```diff
-2. **契约问题**：发现接口字段、路径、鉴权、错误码或兼容性问题时，先由后端评审写入交接 worktree `G:/Dev/backend/Club/coderclub-contract-claude-backend/proposals/backend/`，等待 PM 明确确认；未确认前不得修改实现或契约源。
+2. **契约问题**：发现接口字段、路径、鉴权、错误码或兼容性问题时，先由后端评审写入交接仓库 `proposals/backend/`（当前工作区 `G:/Dev/backend/Club/coderclub-contract-codex-pm`，经角色分支 `codex/backend-contract` 发 PR），等待 PM 明确确认；未确认前不得修改实现或契约源。
```

**③ 第 3 条批准后契约实现——补规则 9 回执双轨：**

```diff
-3. **批准后的契约实现**：对应提案获得 PM 确认后，可以在同一后端实现提交中修改 `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`，并记录批准提案、源文件 SHA-256、验证结果和语义差异。该文件仍是后端运行时契约来源。
+3. **批准后的契约实现**：对应提案获得 PM 确认后，可以在同一后端实现提交中修改 `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`，并记录批准提案、源文件 SHA-256、验证结果和语义差异。该文件仍是后端运行时契约来源。实施完成后按交接仓库规则 9 提交双轨回执（Markdown 正文 + 同目录 `*-summary.json`）。
```

## 3. 执行与验收

1. 后端实现（或评审）在后端 `CLAUDE.md` 应用以上三处 diff，提交遵循 Conventional Commits（如 `docs(governance): align CLAUDE.md with skills-integration and rule 9`）。
2. 涉及写入范围/契约流程，属文档治理补强，无 Java 代码变更、无构建影响。
3. 经 PR 合入后端 `main`（合入人 = 用户或后端评审），CI 全绿；回执按规则 9 双轨落交接仓库 `handoff/backend-to-frontend/2026-08-18/`。
4. 提交消息与 PR 描述遵守规则 8（无真实环境信息）。

- 下发角色：协调 PM
- 日期：2026-08-18