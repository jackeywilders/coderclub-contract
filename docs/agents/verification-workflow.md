# 远程优先核验与完成通知协议

> 生效日期：2026-08-17（协调 PM 经 grilling 讨论定案，见 AGENTS.md 协作规则 9）
> 适用范围：全部五角色（协调 PM / 后端评审 / 后端实现 / 前端评审 / 前端实现）在交接仓库的日常协作
> 关联文档：`AGENTS.md` 规则 9；`.github/workflows/governance-check.yml`（证据门禁实现）

## 1. 背景与问题

本协议解决两个反复出现的工作流反模式：

1. **本地优先核验**：各角色收到"某任务已完成"的通知后，先在本机 worktree 中搜索证据文件，而不是先在远端确认。本地 worktree 可能不含最新 `main`（未 fetch）或含有旧版本文件，导致拿旧内容当权威，甚至"找不到证据"后才发现证据已在远端。
2. **通知不带远端证据**：完成通知只给结论（"回执已提交"），不给实施提交 SHA、回执提交 SHA、PR 号与合入状态。接收方必须先在本地搜索才能定位证据，核验成本高且易错。

## 2. 分级判定：R1（存在性）与 R2（生效性）

"远程"分两个层级，核验要求随声称类型不同：

| 层级 | 判定对象 | 判据 | 适用声称 |
| --- | --- | --- | --- |
| **R1 存在性** | 证据已 push 到远端 | 按通道策略（`docs/agents/remote-channel-policy.md`：MCP/gh API 优先，git fetch 直连兜底）访问远端后在远端分支或 PR 上可见（MCP 读文件/PR、`gh pr view` / `git ls-remote` / `git log origin/<branch>`） | "已提交回执""已签署""已推送" |
| **R2 生效性** | 证据已合入 `main` | 按通道策略访问远端后 `main` 上可见（MCP list_commits/get_file_contents ref=main、`gh api commits/main`、`git merge-base --is-ancestor <sha> origin/main`） | "已合入""已验收""可进入下一阶段" |

**核验动作统一为：先按通道策略访问远端（MCP/gh API 优先，git fetch 兜底；通道全断时排队登记、恢复补推，见 remote-channel-policy §5），再按声称类型查对应层级；禁止仅凭本地 worktree 内容判定。** 若本地没有最新 `main`，必须先经通道获取再判断——"本地找不到"不能作为"远端不存在"的证据。

> 注：auto-merge 机制下，PR 合入 `main` 存在时间窗口。R1 成立时 R2 未必成立（PR 已开但未合入），验收类声称必须等 R2。

## 3. 完成通知必须携带远端状态证据

各角色通知"某任务已完成"时，通知消息（聊天/PR 描述/状态文件）必须包含以下字段，缺一不可，否则视为无效通知、接收方有权要求补齐：

| 字段 | 说明 | 示例 |
| --- | --- | --- |
| 实施提交 SHA | 业务代码/测试的提交（完整或前 7 位） | `ae2bb7e` |
| 回执提交 SHA | 回执文档的提交 | `494e862` |
| PR 号 | 该工作的 PR | `#11` |
| R2 状态 | 是否已合入 `main`（是/否） | 否（待合入） |

字段与回执文件"来源与提交哈希"表头一致，便于接收方定点比对：fetch 后按 SHA 在 `origin/main` 上比对，而不是全仓库搜索。

## 4. 证据门禁（governance-check 只读核验）

`governance-check.yml` 在既有检查（status JSON 语法、`git diff --check`、敏感扫描）之后新增**只读证据核验**，核验不通过则 PR 检查红、不触发 auto-merge：

1. **回执摘要结构校验**：遍历 `handoff/**/*-summary.json`（排除 `_template-*`），校验必填字段完整性与类型（见 §6 模板）。
2. **状态交叉一致性（白名单规则）**：当前覆盖 `status/pm.json`——`m4AcceptanceReports` 含某任务的关闭验收报告 ⇒ `state` 不得声明该任务 `in-progress`；`m4-03Supplement.status = covered` ⇒ `state` 不得再声明对应验证项待补。其余状态文件的白名单规则后续按需扩展。
3. **引用存在性**：校验 `status/pm.json` 与各 `*-summary.json` 中引用的提交 SHA 在仓库历史中存在（`git cat-file -e`，存在性即 R1，不要求已合入 `main`）、引用的文件路径真实存在（`test -f`）。**仅限仓库内引用**：`contractSnapshot.sourceCommit` 是私有后端仓库的提交（快照来源），跨仓库按 §5 人链核验，不在此处校验；`reviewedCommit`/`snapshotCommit` 等仓库内引用必须存在。**不做跨仓库核验**（见 §5）。

**只读原则**：门禁只读远端（fetch + 比对），不写回任何仓库；不做状态自动更新、不自动打标记。写逻辑会引入免费版 token 权限下的 `action_required` 卡死风险（历史教训：`pr-sync-main`），且违背"状态由角色维护"的治理原则。

## 5. 跨仓库核验边界（人链）

实施提交位于私有代码仓库（`coderclub` / `CoderClubFront`），契约仓库的 workflow 无法直接核验（`GITHUB_TOKEN` 仅限本仓库）。跨仓库提交真实性的核验由**人链**承担：

- 后端评审/前端评审在签署回执时比对实施提交 SHA（评审角色有对应代码仓库访问权）；
- 通知时附上人链核验输出（如 `git log -1 <sha>` 的结果），供接收方复核。

**备选（暂不启用）**：如需 workflow 自动化核验私有仓库提交，官方方案是 GitHub App 安装 token（`actions/create-github-app-token`，细粒度 `contents: read`、按仓库授权、1 小时过期自动撤销），而非提高 `GITHUB_TOKEN` 权限（后者无法跨仓库）。仅在出现"回执声称与实施不符"的争议时再启用，启用需用户授权。

## 6. 回执双轨：Markdown 正文 + 结构化摘要

**"回执"= 交接仓库中的文件（Markdown 正文 + 同目录 `*-summary.json`，双轨），≠ 仅聊天/PR 描述中的通知。** 完成通知（§2）携带证据字段**不能代替**回执文件：回执必须作为文件提交到交接仓库对应角色的 `handoff/` 目录（日期目录按规则 6），供 governance-check 校验、接收方取用与审计留痕。通知与回执文件两者都要；缺一属于回执不完整。

执行回执保持 Markdown 正文（人可读的论证与原始输出），另附**同目录结构化摘要** `*-summary.json`（机器可核验的证据声明）。模板见 `handoff/backend-to-frontend/_template-task-receipt-summary.json`。

**回执分支策略（2026-09-01 起，见 role-naming.md 分支治理规范）**：回执直接在各**角色稳定分支**（`pm`/`review/backend`/`impl/backend`/`review/frontend`/`impl/frontend`）上一次性提交并发 PR（governance-check 通过自动合入），**不再创建 `claude/backend-*-receipt`、`*-backfill` 等一次性回执分支**；此类历史一次性分支均已删除。

摘要必填字段（workflow §4.1 校验）：`taskId`、`taskTitle`、`receiptPath`、`sourceProject`、`implementationCommitSha`、`receiptCommitSha`、`pullRequestNumber`、`contractSnapshotSha256`、`verificationResult`、`verificationDate`。

## 7. state 受控枚举

`status/*.json` 的 `state` 字符串**只从受控枚举复制**，禁止手写拼接：state 的合法取值与更新规则由协调 PM 维护（当前以 `pm/reviews/` 验收记录为事实来源，枚举随里程碑在协议文档与状态文件间同步）。`state` 每次更新必须与同批 `m4AcceptanceReports`/补充项字段保持一致（§4.2 白名单规则强制）。

## 8. 分级补救

证据门禁失败的补救按失败类型分级：

| 类型 | 判定 | 处理 |
| --- | --- | --- |
| 笔误/引用类 | 引用与回执内容自身矛盾、明显可修正（如路径写错、SHA 抄错） | 提交者修复后重 push（触发 synchronize 重跑），检查恢复绿色即可合入 |
| 实质不符类 | 引用的 SHA/文件在远端确实不存在，或状态与验收记录矛盾且无法自证 | **红牌**：不自动合入，该任务暂停；由协调 PM 介入核实，必要时退回对应评审重新签署，并在状态文件中记录处置 |
| 跨仓库类 | 私有仓库实施提交核验存疑 | 按 §5 人链处理，PM 决策是否放行 |

## 9. 各角色执行要点（2026-08-17 治理变更同步）

本次治理变更（AGENTS.md 规则 9、本协议、governance-check 证据门禁、双轨回执）已于 2026-08-17 合入 main。各角色按下列动作同步与执行：

| 角色 | 分支 | 同步动作 | 后续执行要求 |
| --- | --- | --- | --- |
| 协调 PM | `pm` | `git merge origin/main` | 维护 state 受控枚举（§7）；验收按 §2 通知字段收证据，并核对 §6 回执文件已落交接仓库 |
| 后端评审 | `review/backend` | `git merge origin/main` | 签署回执时按 §2 自检通知字段、按 §5 人链核验实施提交；回执须在交接仓库落文件（§6 双轨）；工作底稿 + main 合入流程不变 |
| 后端实现 | `impl/backend` | `git merge origin/main` | 执行回执**双轨**：Markdown 正文 + 同目录 `*-summary.json`（模板 `handoff/backend-to-frontend/_template-task-receipt-summary.json`，字段见 §6）**提交到交接仓库 handoff 目录**；完成通知带 §2 四字段远端证据 |
| 前端评审 | `review/frontend` | `git merge origin/main` | 前端侧交接/验收回执同样适用 §2 通知字段与 §5 跨仓库人链核验（前端提交在 CoderClubFront）；前端回执同样须在交接仓库落文件（§6 双轨） |
| 前端实现 | `impl/frontend` | `git merge origin/main` | 前端回执双轨约定沿用 §6 字段（模板随后端方向；如前端回执新增，按 §6 字段结构补 `*-summary.json` 并提交到交接仓库 handoff 目录） |

**当前 M4 状态**：M4 01-06 全部验收关闭（`status/pm.json` `state = gate0-1-m4-all-accepted`）；下一步 Gate 4 发布门禁，`releaseStatus`/`finalReleaseStatus` 变更须用户明确授权。

## 10. 版本记录

- 2026-08-17：初版定案（grilling 讨论 Q1-Q10；实施：AGENTS.md 规则 9 + 本协议 + governance-check 只读核验 + 回执摘要模板）。
- 2026-08-17：新增 §9 各角色执行要点（治理变更同步；M4 01-06 全关、state `gate0-1-m4-all-accepted`）。
- 2026-08-18：补正 §6/§9——明确"回执 = 交接仓库文件（Markdown + `*-summary.json` 双轨）≠ 仅通知"；通知带证据不能代替回执文件，两者都要（根因：合规合入 PR 仅通知带证据、未落回执文件）。
- 2026-08-29：§2 通道表述更新——核验动作由"先 git fetch origin"改为"按通道策略访问远端（MCP/gh API 优先，git fetch 兜底，全断排队登记）"，引用 `docs/agents/remote-channel-policy.md`（背景：GitHub 直连不稳定，实际操作已长期以 MCP/gh API 优先）。
