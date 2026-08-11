# G1-02 前端收口任务单

> **发起角色：** PM / 跨项目协调 Codex
>
> **接收角色：** Frontend Codex
>
> **日期：** 2026-08-11

## 当前结论

G1-02 的前端业务实现和整改已经完成：

- 原始实现提交：`f76e6513164345250aca6b8d1e69984c5736059a`
- 整改提交：`386dd53b936cd3b06ec8a3e29a13989ff15a6463`
- 整改复核报告判定目标行为、测试、lint 和构建复核通过：
  `acceptance/frontend/2026-08-11-g1-02-remediation-review.md`
- G1-05 默认 Node/npm 入口已由用户在本机 CMD 验证并由 PM 正式关闭。

当前剩余工作主要是前端交接证据和状态回写，不要求再次修改业务代码。

## Frontend Codex 待办

### 1. 回写前端状态

修改交接仓库 `status/frontend.json`：

- 将 `acceptance.G1-02` 更新为 `accepted`。
- 将 `lastCommit` 更新为完整提交哈希 `386dd53b936cd3b06ec8a3e29a13989ff15a6463`。
- 将 `lastHandoff` 更新为 `handoff/frontend-to-backend/2026-08-11-g1-02-review-remediation-report.md`。
- 移除 `FRONTEND-BUSINESS-401-403`。
- 保留 `HANDOFF-HASH-MISMATCH`，除非另有证据完成后端快照映射修复。
- 保留前端整体 `state: blocked`，因为其他项目级阻塞项仍存在。

### 2. 补充 G1-02 收口证据

在 `acceptance/frontend/` 新增一份 G1-02 收口记录，或以明确的后续记录补足既有报告，必须包含：

- `f76e6513164345250aca6b8d1e69984c5736059a`、
  `386dd53b936cd3b06ec8a3e29a13989ff15a6463` 和各自父提交的完整哈希。
- 原始审核报告中的 `fa2a981` 短哈希对应的完整提交哈希。
- G1-02 代码整改与 G1-05 默认 Node/npm 环境验证的边界说明。
- 明确区分直接命令验证、等价 Node 验证和用户本机 CMD 确认，不补写未实际取得的版本或日志。
- 记录未修改 OpenAPI、交接仓库 `api/` 和 `status/sync-manifest.json`。

### 3. 验证交接引用

只读核对以下内容，并在收口记录中给出结果：

```powershell
git show 386dd53b936cd3b06ec8a3e29a13989ff15a6463
git diff cb62823f5944d4f544a3f11da8685900a5d8cfb4..386dd53b936cd3b06ec8a3e29a13989ff15a6463 --name-status
```

预期修改范围为 G1-02 原始实现和整改涉及的前端文件；不新增 API 契约变更。

## 远端代码发布边界

当前前端业务提交 `386dd53` 位于本地 `CoderClubFront/main`。既有交接报告记录未直接推送 `main`。

- 不得直接推送前端 `main`。
- 如需要将前端实现发布到远端，由用户另行授权后，Claude Code 前端创建非 `main` 分支并提交 PR。
- Frontend Codex 不代替 Claude Code 前端修改前端业务项目或执行代码发布。

该项是远端可见性事项，不阻止本地代码行为验收，但在远端交接要求下必须单独记录结果。

## PM 后续动作

Frontend Codex 完成上述回执后，PM 再执行：

- 从 `status/pm.json.openFindings` 移除 `G1-02-FRONTEND-BUSINESS-401-403`。
- 更新 PM 审核提交和 `reviewedCommit`，使其对应当前同步的 `origin/main`。
- 维持 `G1-03`、`G1-04` 以及 `HANDOFF-HASH-MISMATCH` 的独立状态。

PM 不要求 Frontend Codex 修改 `status/sync-manifest.json`、API 快照或发布状态。

## 完成条件

- `status/frontend.json` 已记录 G1-02 accepted、完整实现提交和最新交接回执。
- 新增收口记录包含完整哈希、验证边界和无契约变更声明。
- `git diff --check` 和 `git status --short` 结果已记录。
- 未修改前端业务代码、后端项目、API 快照或发布状态。
