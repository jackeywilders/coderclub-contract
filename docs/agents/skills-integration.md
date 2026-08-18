# 工程技能与仓库治理适配细则

> 日期：2026-08-18
> 定位：协调 matt-pocock 系列工程技能（brainstorming / grilling / writing-plans / executing-plans / to-tickets / to-spec 等）与 CoderClub 三仓库治理规则的冲突与分工。
> 顶层原则仍适用：AGENTS.md 治理优先；本文件是技能在治理框架内的落点与边界说明。

## 1. 背景：三处冲突及化解

工程技能（尤其 brainstorming/writing-plans）对产出物有硬性约定，曾与仓库规则冲突：

1. **路径/命名冲突**：技能要求设计/计划文档存 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`、`docs/superpowers/plans/YYYY-MM-DD-<feature>.md`（文件名带日期前缀、固定目录），与规则 6"先建日期目录、文件名不带日期前缀"相抵。
   - 化解：规则 6 已把 `docs/superpowers/**` 加入豁免清单（2026-08-18）。
2. **定位分叉**：技能的"设计/计划"与仓库的"Proposal"是两套产物，易双轨重复或绕过审批。
   - 化解：见 §2 分层。
3. **落点越界**：技能会创建文件/操作 issue，可能触碰只读边界。
   - 化解：见 §3 角色落点。

## 2. 分层：spec/plan 与 proposal

| 维度 | 技能 specl/plan（`docs/superpowers/**`） | 仓库 proposal（`proposals/**`） |
| --- | --- | --- |
| 解决什么 | 怎么做（实现细节、实施计划） | 应不应该改契约 / 跨项目影响 / 是否需 PM 确认 |
| 放哪 | 所属代码仓库 `docs/superpowers/` | 交接仓库 `proposals/后端` 或 `proposals/前端` |
| Owner | 实现角色 | 评审角色 + PM 决策 |
| 审批 | 无（实现内部） | PM 明确确认 |
| 契约变更覆盖 | **不覆盖、不替代** | 必须（接口字段/路径/方法/鉴权/错误码/兼容性） |

**铁律**：任何涉及接口字段、路径、方法、鉴权、错误码或兼容性的变更，必须走 `proposals/` + PM 确认，spec/plan 不能替代、不能先行绕过；纯内部实现（解除 mock、重构、补测试、非契约代码）可直接由 spec/plan 承载。

## 3. 角色落点与只读边界

| 角色 | 技能产物落点 | issue 落点 |
| --- | --- | --- |
| 后端实现 | 后端 `CoderClub/docs/superpowers/**` | 后端仓库本地 `.scratch/<feature>/` |
| 前端实现 | 前端 `CoderClubFront/docs/frontend/superpowers/**` | 前端仓库本地 `.scratch/<feature>/` |
| 后端评审 | 交接仓库 `proposals/backend/`、`designs/backend/` | 交接仓库 `.scratch/` |
| 前端评审 | 交接仓库 `proposals/frontend/`、`designs/frontend/` | 交接仓库 `.scratch/` |
| 协调 PM | 交接仓库 `pm/`、`docs/agents/` 等治理路径 | 交接仓库 `.scratch/` |

**禁止**：任何技能产物不得写入交接仓库治理文件（`AGENTS.md`/`CLAUDE.md`/`docs/agents/**`）、`api/**` 快照、`status/sync-manifest.json`；不越界写入角色无权目录。交接仓库的 issue 跟踪按 `docs/agents/issue-tracker.md`（`.scratch/<feature>/` + `needs-*` 标签）。

## 4. 技能触发与治理的衔接

- 技能激活是**实现层内部流程**（探索→设计→计划→子代理执行），不改变仓库的远端合入流程（角色分支 + PR + 人工合入）。
- `executing-plans` / `subagent-driven-development` 按任务书执行；实施回执仍按规则 9 双轨落交接仓库。
- 若技能要求写入超出上表落点的路径：停下来，向 PM/用户确认，不擅自扩大写入范围。

## 5. 版本记录

- 2026-08-18：创建（brainstorming + grilling 讨论；Q1 豁免、Q2 分层、Q3 落点三项定案；同步 AGENTS.md 规则 6）。