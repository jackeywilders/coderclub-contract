# Mnemon 记忆系统集成——后端实现（B-Impl）执行方案（2026-09-02）

> 适用角色：后端实现（B-Impl）
> 配套：`2026-09-02-memory-integration-master.md`（总领，先读）
> 本方案定义 B-Impl 的记忆动作。代码开发在后端源码仓；回执/PR 在交接仓（`impl/backend` 分支）——**写记忆的回执类动作须在交接仓根会话执行**。

## 1. 角色定位与记忆边界

B-Impl 负责后端业务实现、测试、实现证据：
- **记**：本模块（subject/practice/circle/interview/...）的归属、契约语义、实现坑与修复根因、工具经验。
- **不记**：评审主观结论（B-Review 记）、PM 未决判断、密钥凭据、编译日志原始输出。

## 2. 每轮启动动作

1. 确认 Runtime 快照（MEMORY.md 分支体系/工具约定就位）；
2. `mnemon_recall` 本模块历史结论与坑（关键词如 `后端 subject Meili|Redis 归属`）；
3. 动手前如涉及既有契约，`mnemon_document_search` 检索契约快照要点/相关任务书。

## 3. 写入动作

| 时机 | 写入内容 | 层 |
| --- | --- | --- |
| 实现完成 | 实现回执 Documents（sourcePath 指向 `handoff/backend-to-frontend/...`） | Documents |
| 修复闭环 | Space 条目（`[B-Impl-<模块>] 根因/修复：…`，如 `[B-Impl-circle] 词库写路径失效→rebuild 强制 DB 重载`） | Space |
| 发现工具坑 | Space/MEMORY 补充（如「裸 bash 被 WSL 劫持，用绝对路径」） | Space/MEMORY |
| 稳定模块约定 | 补充 MEMORY（若 PM 未覆盖） | MEMORY（补充） |

## 4. 召回动作（典型查询）

- 开工前：`后端 <模块> 归属 契约 上次实现`
- 复用结论：`subject Meili 降级 LIKE category_ids`
- 历史坑：`Redis FIX 敏感词 锁 interview 前缀`

## 5. 禁止项

- 不写临时进度 / 编译日志 / 未验证猜测；
- 密钥/凭据不入任何层（含 `.env` 模板值）；
- 回执 Documents 只写「结论 + 证据」，不灌过程日志。

## 6. 执行清单（本方案落地动作）

1. 阅读本方案 + 总领；
2. 阶段 5（协调人转发后）：写 1-2 条本模块 Space 种子（如 `[B-Impl-subject] getSubjectPageBySearch 契约不变、Meili 降级 LIKE`）；
3. 日常实现/回执遵循 §3/§4 动作；
4. 契约/记忆约定问题 → 走提案或告知 PM。

## 7. 版本记录

- 2026-09-02：创建。
