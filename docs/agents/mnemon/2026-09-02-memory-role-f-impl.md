# Mnemon 记忆系统集成——前端实现（F-Impl）执行方案（2026-09-02）

> 适用角色：前端实现（F-Impl）
> 配套：`2026-09-02-memory-integration-master.md`（总领，先读）
> 本方案定义 F-Impl 的记忆动作。代码开发在前端源码仓；回执/PR 在交接仓（`impl/frontend` 分支）——**写记忆的回执类动作须在交接仓根会话执行**。

## 1. 角色定位与记忆边界

F-Impl 负责前端业务实现、测试、基线更新：
- **记**：消费的契约快照语义、页面-接口对应、前端模块（circle/message/practice/interview/...）的实现约定与坑。
- **不记**：评审主观结论、后端内部细节、密钥凭据、构建日志原始输出。

## 2. 每轮启动动作

1. 确认 Runtime 快照（MEMORY.md 分支体系/工具约定就位）；
2. `mnemon_recall` 本模块历史实现结论（关键词如 `前端 circle|message|practice 实现`）；
3. 涉及接口语义时 `mnemon_document_search` 检索快照/任务书/后端回执。

## 3. 写入动作

| 时机 | 写入内容 | 层 |
| --- | --- | --- |
| 实现完成 | 实现回执 Documents（sourcePath 指向 `handoff/frontend-to-backend/...`） | Documents |
| 修复闭环/坑 | Space 条目（`[F-Impl-<模块>] 坑/修复：…`，如 `[F-Impl-message] 未读高亮用 isRead 读取时点值`） | Space |
| 契约问题上报 | 提案 Documents（`proposals/frontend/`） | Documents |
| 稳定前端约定 | 补充 MEMORY（若 PM 未覆盖） | MEMORY（补充） |

## 4. 召回动作（典型查询）

- 开工前：`前端 <模块> 契约 上次实现 页面`
- 复用语义：`MessageVO isRead fromId 基线`
- 历史坑：`前端 基线 api:check 交互`

## 5. 禁止项

- 不写临时进度 / 构建日志 / 未验证猜测；
- 密钥/凭据不入任何层；
- 回执 Documents 只写「结论 + 证据」，不灌过程日志。

## 6. 执行清单（本方案落地动作）

1. 阅读本方案 + 总领；
2. 阶段 5（协调人转发后）：写 1 条本模块 Space 种子（如 `[F-Impl] 基线 75 endpoints，api:check 无差异才算通过`）；
3. 日常实现/回执遵循 §3/§4 动作；
4. 契约/记忆约定问题 → 走提案或告知 PM。

## 7. 版本记录

- 2026-09-02：创建。
