# Issue 跟踪配置

## 后端

本仓库使用本地 Markdown 作为 Issue 跟踪器，不调用 GitHub、GitLab、Gitee 或其他远端 Issue CLI。

## 存放位置

Issue 存放在：

```text
.scratch/<feature>/
```

建议每个 Issue 使用一个目录，并在其中创建 `issue.md`。Issue 可以附带复现记录、日志摘要、契约片段和验收证据，但不得写入密码、Token 或其他敏感凭据。

## 最小字段

每个 Issue 至少包含：标题、当前标签、提出角色、负责人、背景或复现条件、影响范围、验收标准、相关提交哈希和最后更新时间。

## 工作流

新 Issue 使用 `needs-triage`；信息不足时使用 `needs-info`；范围和验收标准清晰后使用 `ready-for-agent`；需要 PM 或用户决策时使用 `ready-for-human`；确认不处理时使用 `wontfix`。
