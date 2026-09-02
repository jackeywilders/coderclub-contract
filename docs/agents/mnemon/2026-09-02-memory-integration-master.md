# Mnemon 记忆系统集成——总领方案（2026-09-02）

> 编写角色：协调 PM
> 日期：2026-09-02（Asia/Shanghai）
> 流程：/grill-me 八轮决策收敛（Q1-Q8）+ /brainstorming 设计定案
> 依据：`pm/reviews/2026-09-02/` 设计记录 + 本目录五份角色方案
> 配套：五角色各自阅读执行 `2026-09-02-memory-role-{pm,b-review,b-impl,f-review,f-impl}.md`

## 0. 本方案解决什么

CoderClub 是「交接仓协调 + 前后端分离 + 多角色 agent」的协作流水线。其固有痛点是**跨会话遗忘**与**角色/项目上下文串扰**。Mnemon 记忆插件提供三层记忆（Runtime / Documents / Memory Spaces），本方案将项目协作事实按权威模型映射进各层，让每个角色会话「启动即就位、跨任务不丢结论、上下文不串扰」。

真实插件状态（2026-09-02 实测）：1 个激活 Memory Space（`default`，mnemon-native，全能力），可写；记忆根 = 交接仓 workspace `.mnemon`（`G:\Dev\backend\Club\coderclub-contract\.mnemon`）；全局根 `C:\Users\Sakura\.mnemon` 承载跨项目 USER 偏好。

## 1. 三层映射（Q2 定案）

| 你的项目事实 | 记忆层 | 说明 |
| --- | --- | --- |
| 角色稳定身份/偏好/沟通习惯 | **Runtime USER.md**（target=user） | 每轮自动投影，全局根承载跨项目部分 |
| 项目稳定约定（分支体系/工具选择/验收规范/批次状态） | **Runtime MEMORY.md**（target=memory） | 每轮自动投影，交接仓根 |
| 完整任务书/规格/验收记录/SOP/回执模板 | **Documents**（交接仓根 active） | 保留全文，按需 `document_search` |
| 跨任务可复用结论（模块归属/契约决策/评审教训/根因） | **Memory Space `default`** | 跨任务 `recall`，逻辑分区 |

**架构决策（Q2=A）**：单一共享 Memory Space `default` + 三层分层，**不建多物理 Space**；按角色隔离靠「条目前缀 + 描述路由」逻辑分区。理由：当前插件单根共享数据面（mnemon.db 可被同根 agent 共享），物理多 Space 需多 storageRoot，收益低维护高（YAGNI）。

## 2. 写入权威模型（Q3 定案）

| 层 | 谁主导写 | 谁补充 |
| --- | --- | --- |
| Runtime USER | **各角色自己**（身份/偏好） | PM 不代写他人 |
| Runtime MEMORY | **PM 维护项目级** | 各角色补充本模块稳定约定 |
| Documents 任务/验收类 | **PM** | — |
| Documents 回执/签署类 | **对应角色**（B-Impl/F-Impl 回执、B-Review/F-Review 签署） | — |
| Space `default` | **各角色写本模块结论**（条目前缀隔离） | PM 播项目级种子 |

**分层写入纪律**：临时进度、编译日志、原始输出、密钥**一律不写入任何层**——这是 token 增长与污染的根源（官方明确建议跳过）。

## 3. 六角色记忆动作总表

| 角色 | 会话启动 recall | 主要写入 |
| --- | --- | --- |
| 协调 PM | 批次状态 / 未决任务 / 待验收线 | MEMORY 项目约定、Documents 任务书+验收、Space 项目状态种子 |
| 后端评审 B-Review | 本模块历史评审结论 / 提案上下文 | Documents 签署记录、Space 评审教训 |
| 后端实现 B-Impl | 本模块归属 / 契约约定 / 历史坑 | Space 模块结论、回执 Documents（经交接仓） |
| 前端评审 F-Review | 契约消费基线 / 验收标准 | Documents 前端签署、Space 前端验收教训 |
| 前端实现 F-Impl | 消费的契约快照语义 / 交互约定 | Space 前端模块结论 |

## 4. 记忆根与隔离约定

- **唯一项目记忆根**：交接仓 `.mnemon`（workspace 模式，跨角色共享）。
- **全局根**：`C:\Users\Sakura\.mnemon`——USER 跨项目偏好（如中文交流）。
- **逻辑分区规则**（单 Space 内）：
  - 条目 content 以 `[角色-模块]` 前缀开头（如 `[B-Impl-subject] Meili 降级语义…`）；
  - `mnemon_recall` 检索时按角色/模块关键词限定；
  - 描述路由（Space description）写明「CoderClub 项目级长期记忆」。
- 后端/前端源码仓**不建独立 `.mnemon`**（报告建议的 workspace 隔离在本插件下无收益且增维护）。

## 5. 播种计划（Q5/Q8 定案，分工播种）

**PM 播种（项目级权威事实，阶段 3）**：
- MEMORY.md：分支体系（pm/review/impl）、工具选择（Git Bash 绝对路径/禁裸 bash/jq）、协作要点（规则 9/10）；
- Space `default`：模块-服务归属、契约快照要点、批次状态种子（「第二批四线已验收」）、工具坑（裸 bash 被 WSL 劫持）、当前推进项（interview 后端/前端）。

**角色播种（个人级，阶段 5，角色自己执行）**：各角色 USER 偏好 + 本模块经验，按各自方案。

## 6. C 层固化清单（Q6 定案，全覆盖）

| 文件 | 改动 | 执行者/合入 |
| --- | --- | --- |
| `docs/agents/mnemon/2026-09-02-*.md` ×6 | 本方案 + 五角色方案 | PM，`pm` 分支 PR 自动合入 |
| 交接仓 `AGENTS.md` | 协作规则补「记忆系统使用」（规则 11） | PM，同上 |
| 后端 `CoderClub/CLAUDE.md` | 「记忆约定」小节 | PM（权限内），后端 PR（用户手动） |
| 前端 `CoderClubFront/CLAUDE.md` | 「记忆约定」小节 | PM（权限内），前端 PR（用户手动） |

## 7. 执行阶段（Q8 定案）

1. **文档层**：起草六份 → `pm` 分支 PR 合入交接仓 main；
2. **Documents 注册**：六份方案注册进交接仓 `.mnemon` Documents（sourcePath 指向交接仓文件）；
3. **真实播种（PM）**：MEMORY.md + Space 写入项目权威种子；
4. **C 层固化**：交接仓 `AGENTS.md` + 后端/前端 `CLAUDE.md` → 三仓 PR；
5. **角色认领**：四角色按各自方案个人播种与会话动作（协调人转发，PM 不代做）。

## 8. 禁止项（全角色）

- 密钥 / Token / 私钥 / 凭据：**不入任何记忆层**（无确定性 secret 扫描器，2026-09-01 治理批次确认）。
- 临时进度 / 原始日志 / 大段输出 / 猜测：不写入。
- 未经验证的第三方脚本内容：不写入。
- Documents 仅承载「完整、需要时快速阅读」的知识，非流水账。

## 9. 版本记录

- 2026-09-02：创建（grill-me Q1-Q8 + brainstorming 定案）。
