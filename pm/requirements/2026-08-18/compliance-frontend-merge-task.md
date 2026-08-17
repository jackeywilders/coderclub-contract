# 前端治理补强合入任务书（交前端评审）

> **任务角色：** 前端评审（F-Review）
> **下发角色：** 协调 PM
> **日期：** 2026-08-18
> **来源：** 合规补强清单 `docs/agents/governance-compliance-recommendations.md`（PR #15 已合入 main）A/B/C/H 组
> **仓库现状：** 改动已在**本地 `main` 分支提交**，未推送远端；本地 `main` 领先 `origin/main` **1 个提交**（见下）

## 1. 任务内容

将前端本地 `main` 上的治理补强提交经 PR 合入前端远端 `main`（遵守前端约定：合入由人工在 GitHub 执行，`CLAUDE.md` 明确"合入人 = 用户或前端评审"）。

## 2. 提交与影响范围

| 提交 | 内容 | 影响文件 | 影响范围 |
| --- | --- | --- | --- |
| **`df9efa1`**（docs(governance): adopt global compliance recommendations A/H/B/C） | 本次治理补强：AGENTS.md 补远程优先核验（R1/R2）+ 敏感范围扩围（key/token/凭据）；CLAUDE.md 补验证被拦截处理 + 运行资源自管理 | `AGENTS.md`、`CLAUDE.md` | 文档/治理，无 `src/` 代码变更，无构建/测试影响 |

## 3. 推荐执行步骤

1. 在本地 `main`（含 `df9efa1`）从当前 HEAD 创建独立 feature 分支（如 `docs/governance-compliance` 或按前端惯例命名），**不要直接在 main 上 push**。
2. push 该分支到前端远端；开 PR 到 `main`，PR 标题/描述注明"治理补强（合规清单 A/B/C/H）"。
3. 等待前端 `ci` workflow（`npm test`、lint、api:check、build）。本次为纯文档变更，预计全绿；若 docs-only 有跳过机制则按 CI 实际行为。
4. CI 全绿后，合入人（用户或前端评审）在 GitHub 手动合入 PR。
5. 合入后按交接仓库规则 9 在通知中携带：实施提交 SHA、回执提交 SHA、PR 号、R2 状态（已合入 `main`）。

## 4. 验证与注意事项

- 本次补强内容与合规清单 A/B/C/H 组一致（清单见 `docs/agents/governance-compliance-recommendations.md`），无需二次设计评审，按清单落地即可。
- 前端 `AGENTS.md` 现有的"合入由人工在 GitHub 执行"未明确合入人，`CLAUDE.md` 已注明"用户或前端评审"——此差异已知悉并留档，不在本任务范围。
- 提交消息与 PR 描述遵守规则 8（无真实环境信息）。

- 下发角色：协调 PM
- 日期：2026-08-18