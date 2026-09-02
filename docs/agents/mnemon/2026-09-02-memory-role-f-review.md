# Mnemon 记忆系统集成——前端评审（F-Review）执行方案（2026-09-02）

> 适用角色：前端评审（F-Review）
> 配套：`2026-09-02-memory-integration-master.md`（总领，先读）
> 本方案定义 F-Review 的记忆动作。会话在交接仓 worktree（`-review-frontend`，`review/frontend` 分支）下启动。

## 1. 角色定位与记忆边界

F-Review 负责前端契约消费复核、验收、阻塞报告：
- **记**：前端消费的契约基线语义、验收标准、发现的前端-契约不一致、签署事实。
- **不记**：F-Impl 实现过程、后端内部细节、密钥凭据。

## 2. 每轮启动动作

1. 确认 Runtime 快照（MEMORY.md 项目约定）；
2. `mnemon_recall` 前端契约基线/验收教训（关键词如 `前端 验收 契约 基线 75`）；
3. 复核前 `mnemon_document_search` 检索验收标准/快照要点/相关回执。

## 3. 写入动作

| 时机 | 写入内容 | 层 |
| --- | --- | --- |
| 完成前端签署 | 签署记录 Documents（sourcePath 指向 `acceptance/frontend/...`） | Documents |
| 发现契约-前端不一致 | Space 条目（`[F-Review-<模块>] 契约差异：…`） | Space |
| 验收教训/阻塞根因 | Space（如 `[F-Review] 基线须 api:check 与快照 SHA 比对`） | Space |
| 稳定约定补充 | MEMORY（若 PM 未覆盖） | MEMORY（补充） |

## 4. 召回动作（典型查询）

- 复核前：`<任务> 验收标准 前端消费 快照`
- 基线语义：`MessageVO isRead 前端 message 页面`
- 已知阻塞：`前端 fromId 契约 差异`

## 5. 禁止项

- 不代写 F-Impl 模块经验 / 用户偏好；
- 密钥/凭据/临时输出不入任何层；
- 验收签署须「已核验远端」（R1/R2）后才写入。

## 6. 执行清单（本方案落地动作）

1. 阅读本方案 + 总领；
2. 阶段 5（协调人转发后）：写 1 条前端评审 Space 种子（如 `[F-Review] api:check 与交接仓快照 SHA 逐字节一致才算基线通过`）；
3. 日常复核/验收遵循 §3/§4 动作；
4. 发现契约问题 → 走 `proposals/frontend/`（评审目录），不擅改总领。

## 7. 版本记录

- 2026-09-02：创建。
