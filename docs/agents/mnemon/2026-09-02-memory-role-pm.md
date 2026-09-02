# Mnemon 记忆系统集成——协调 PM 执行方案（2026-09-02）

> 适用角色：协调 PM
> 配套：`2026-09-02-memory-integration-master.md`（总领，先读）
> 本方案定义 PM 角色的记忆动作：记什么、何时写、何时召回、禁止什么。

## 1. 角色定位与记忆边界

PM 是记忆系统的**播种与维护主导者**（写入权威模型 Q3=A 中 PM 主导项）：
- **记**：项目级稳定约定、批次/任务流转状态、决策与验收结论、跨任务可复用事实。
- **不记**：他人个人偏好（各角色自写 USER）、实现层模块经验（B-Impl/F-Impl 自写）、临时进度与密钥。

## 2. 每轮启动动作

会话开始（或上下文压缩后），先完成记忆就位：
1. 确认 Runtime 快照已投影（USER.md 中文偏好 / MEMORY.md 项目约定）；
2. `mnemon_recall` 检索当前批次状态与未决事项（关键词如 `批次 状态 待验收 interview`）；
3. `mnemon_document_search` 检索在途任务书/待办（如需要全文）。

## 3. 写入动作（PM 职责）

| 时机 | 写入内容 | 层 |
| --- | --- | --- |
| 治理变更定案 | 分支体系 / 工具选择 / 权限扩展等约定 | MEMORY（target=memory） |
| 派发新任务 | 任务书 Documents（sourcePath 指向 `pm/requirements/...`） | Documents |
| 验收通过 | 验收记录 Documents + Space 状态种子（`[PM] 批次状态：…`） | Documents + Space |
| 批次收口 | 更新项目状态种子（如「第二批四线已验收」） | Space |
| 跨会话恢复 | 重读 MEMORY + recall 后继续，不凭记忆续作 | — |

## 4. 召回动作（典型查询）

- 当前推进项：`interview interview 后端 interview 前端 待办`
- 某线状态：`验收 已验收 R2-BACKUP Redis Meili isRead`
- 历史决策：`分支改名 review/backend 工具选择 Git Bash`

## 5. 禁止项

- 不写他人 USER / 模块经验（Q3/Q5 分工边界）；
- 密钥/凭据/临时进度一律不入任何层；
- 不把「未核验远端」的声称写为已生效结论（规则 9 纪律延续）。

## 6. 执行清单（本方案落地动作）

1. 阶段 1 已由本会话完成：六份方案起草 + PR 合入 main；
2. 阶段 2：将六份方案注册进交接仓 `.mnemon` Documents（`document_manage`，sourcePath 指向 `docs/agents/mnemon/` 文件）；
3. 阶段 3：向 MEMORY.md + `default` Space 播种项目级权威种子（分支体系/工具选择/批次状态/模块归属）；
4. 阶段 4：交接仓 `AGENTS.md` 补规则 11（记忆系统使用）+ 后端/前端 `CLAUDE.md` 补「记忆约定」→ 三仓 PR；
5. 阶段 5：向协调人提供四角色「角色认领转发话术」，不代角色播种。

## 7. 版本记录

- 2026-09-02：创建。
