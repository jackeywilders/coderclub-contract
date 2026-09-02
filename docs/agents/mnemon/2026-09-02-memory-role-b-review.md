# Mnemon 记忆系统集成——后端评审（B-Review）执行方案（2026-09-02）

> 适用角色：后端评审（B-Review）
> 配套：`2026-09-02-memory-integration-master.md`（总领，先读）
> 本方案定义 B-Review 的记忆动作。会话应在交接仓 worktree（`-review-backend`，`review/backend` 分支）下启动，记忆根即交接仓 `.mnemon`。

## 1. 角色定位与记忆边界

B-Review 负责后端契约提案、回执复核签署、验收证据：
- **记**：本模块历史评审结论、提案上下文、发现的坑与根因、签署事实。
- **不记**：他人实现细节过程、PM 未决判断、密钥凭据。

## 2. 每轮启动动作

1. 确认 Runtime 快照（MEMORY.md 项目约定就位）；
2. `mnemon_recall` 本模块历史评审结论与坑（关键词如 `后端评审 签署 subject|practice|circle|interview`）；
3. 复核某回执前，`mnemon_document_search` 检索任务书/验收标准/实现回执全文。

## 3. 写入动作

| 时机 | 写入内容 | 层 |
| --- | --- | --- |
| 完成签署 | 签署记录 Documents（sourcePath 指向 `acceptance/backend/...`） | Documents |
| 发现评审坑/根因 | Space 条目（`[B-Review-<模块>] 评审教训：…`） | Space |
| 契约提案定稿 | 提案 Documents（若需跨会话引用） | Documents |
| 补充稳定约定 | 后端模块级约定（仅当 PM 未覆盖） | MEMORY（补充） |

## 4. 召回动作（典型查询）

- 复核前：`<任务ID> 任务书 验收标准 实现回执`
- 本模块历史：`后端评审 subject Meili 降级 评审`
- 已知坑：`后端 Redis 敏感词 词库 FIX`

## 5. 禁止项

- 不代写 B-Impl 模块经验 / 用户偏好；
- 密钥/凭据/临时输出不入任何层；
- 签署声称必须「已核验远端」（规则 9 + verification-workflow §2）后才写入。

## 6. 执行清单（本方案落地动作）

1. 阅读本方案 + 总领；
2. 阶段 5（协调人转发后）：向 MEMORY 补充后端评审侧稳定约定（如有）；向 Space 写入一条「评审教训」种子示例（如 `[B-Review] 签署须核验 receiptCommitSha + 远端 R2`）；
3. 日常复核/签署遵循本方案 §3/§4 的写与召回动作；
4. 发现记忆约定问题 → 走 `proposals/backend/` 或告知 PM，不擅改总领。

## 7. 版本记录

- 2026-09-02：创建。
