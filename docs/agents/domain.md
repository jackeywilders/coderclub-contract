# 领域文档配置

## 布局

本仓库采用单上下文布局：

- 根上下文：`CONTEXT.md`
- 架构决策记录（Architecture Decision Record，ADR）：`docs/adr/`

没有 monorepo 信号，因此不创建 `CONTEXT-MAP.md`，也不为后端和前端建立独立上下文文件。

## 消费规则

Agent 开始任务前读取 `CONTEXT.md`、`AGENTS.md`、`CLAUDE.md` 和 `docs/INDEX.md`。如果任务涉及架构、契约、权限、数据边界或跨项目决策，再读取相关 ADR、提案、交接和验收记录。

## ADR 规则

ADR 文件使用 `docs/adr/NNNN-short-title.md` 命名，记录背景、决策、备选方案、影响、迁移或回滚方式，以及决策状态。ADR 记录已经确认的架构决策；尚未确认的契约变化必须先进入 `proposals/backend/` 或 `proposals/frontend/`。

后端和前端项目中的实现与权威 API 仍以各自项目为准，领域文档只提供共享上下文、决策依据和交接引用。
