# 后端治理补强合入任务书（交后端评审）

> **任务角色：** 后端评审（B-Review）
> **下发角色：** 协调 PM
> **日期：** 2026-08-18
> **来源：** 合规补强清单 `docs/agents/governance-compliance-recommendations.md`（PR #15 已合入 main）A/B/C 组
> **仓库现状：** 改动已在**本地 `main` 分支提交**，未推送远端；本地 `main` 领先 `origin/main` **2 个提交**（见下）

## 1. 任务内容

将后端本地 `main` 上的治理补强提交经 PR 合入后端远端 `main`（遵守后端 AGENTS.md："`main` 不接受直接 push；合入人 = 用户或后端评审"）。

## 2. 提交与影响范围

| 提交 | 内容 | 影响文件 | 影响范围 |
| --- | --- | --- | --- |
| **`a9c2142`**（docs(governance): adopt global compliance recommendations A/B/C） | 本次治理补强：AGENTS.md 补远程优先核验（R1/R2）；CLAUDE.md 补验证被拦截处理 + 运行资源自管理（第 9/10 条） | `AGENTS.md`、`CLAUDE.md` | 文档/治理，无 Java 代码变更，无构建影响 |
| **`ae2bb7e`**（feat(subject): M4-06 运行时移除列表项分页装饰字段 pageNo/pageSize） | 历史遗留：M4-06 实施提交（已获 PM 验收：`pm/reviews/2026-08-17/m4-06-close-acceptance.md`），但**仍未出现在后端远端 main**（本地领先原因） | Java 源码 + 测试 | M4-06 验收已通过，本属应合入内容 |

> 注意：`ae2bb7e` 是本次补强提交的前置历史遗留，非本次新改动。M4-06 已在交接仓库 PM 验收关闭，其合入后端 main 属既定应收尾事项；请一并核实处理。

## 3. 推荐执行步骤

1. 在本地 `main`（含以上 2 提交）从当前 HEAD 创建独立 feature 分支（如 `docs/governance-compliance` 或按后端惯例命名），**不要直接在 main 上 push**。
2. push 该分支到后端远端；开 PR 到 `main`，PR 标题/描述注明"治理补强 + M4-06 实施收尾"。
3. 等待后端 `ci` workflow：`build-and-test`（Java/pom 变更时 `mvn test`）+ `sensitive-scan`。`a9c2142` 为文档变更、`ae2bb7e` 为 Java 变更且测试已绿（M4-06 回执 §4 全模块 BUILD SUCCESS），预计 CI 可通过。
4. CI 全绿后，合入人（用户或后端评审）在 GitHub 手动合入 PR。
5. 合入后按交接仓库规则 9 在通知中携带：实施提交 SHA、回执提交 SHA、PR 号、R2 状态（已合入 `main`）。

## 4. 验证与注意事项

- 本次补强内容与合规清单 A/B/C 组一致（清单见 `docs/agents/governance-compliance-recommendations.md`），无需二次设计评审，按清单落地即可。
- 若 `ae2bb7e` 的合入存在流程疑问（如当时 M4-06 应走却未走），按交接仓库 M4-06 验收记录为准，属收尾而非新决策；如需 PM 决策随时回报。
- 提交消息与 PR 描述遵守规则 8（无真实环境信息）。

- 下发角色：协调 PM
- 日期：2026-08-18