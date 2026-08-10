# Frontend Gate 0/1 契约消费回执

> 回执角色：Frontend Codex
> 日期：2026-08-10
> 回执范围：G0-04、G1-02 前端部分、G1-05

## 1. 来源与消费文件

| 项目 | 值 |
| --- | --- |
| 前端项目 | `G:/Dev/backend/Club/CoderClubFront` |
| 前端来源分支 | `main` |
| 前端来源提交 | `cb62823f5944d4f544a3f11da8685900a5d8cfb4` |
| 交接 worktree | `G:/Dev/backend/Club/coderclub-contract-codex-frontend` |
| 交接分支 | `codex/frontend-design` |
| 实际消费契约路径 | `G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json` |
| 实际消费契约 SHA-256 | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |
| OpenAPI / 路径 / 操作 | `3.0.3 / 45 / 47` |

前端的被忽略配置 `local/api-docs-path.txt` 已从无法证明来源的交接副本改为后端权威源文件。交接仓库
`api/coderclub-openapi.json` 实际仍为 `87e122...`；Backend 回执声明的脱敏副本为 `0057e69...`，
两者不一致，前端不消费该副本，也没有修改 `api/` 或 `status/sync-manifest.json`。

## 2. 验证结果

执行环境：Node `v22.14.0`，npm `10.9.2`。由于 `nvm-desktop` 默认 shim 仍提示未设置默认版本，
验证命令在当前进程临时将 `G:\Dev\env\nodejs\versions\22.14.0` 放到 PATH 首位后执行。

| 命令 | 结果 |
| --- | --- |
| `npm run api:check` | 通过：OpenAPI 3.0.3，47 个操作，SHA-256 为后端源 `44cbe7...`，无契约结构差异 |
| `npm test` | 通过：2 个测试通过，0 失败 |
| 默认 `npm run api:check` | 阻塞：`nvm-desktop: The default Node version is not set` |

G0-04 的消费路径和哈希已完成重新核验。G1-05 的项目命令可在明确 Node PATH 后真实执行，但本机默认
Node 选择器仍需用户环境层面修复，不能报告为永久环境配置已恢复。

## 3. 首轮消费范围与方法

| 模块 | 当前正式方法 | 鉴权结论 | 状态 |
| --- | --- | --- | --- |
| 认证与用户信息 | Auth 原有方法 | 匿名登录/注册；其余按 Backend G1 回执 | 设计已更新，业务消费冻结 |
| 分类与标签 | 更新 PUT，删除 DELETE；POST 仅兼容 | login | 前端 API 文件已使用正式 PUT/DELETE |
| 题目分页与详情 | POST 分页，GET 详情 | login | 设计已更新，等待 Gate 放行 |
| OSS 上传 | POST 上传 | anonymous（当前运行时矩阵） | 未进入正式联调 |

Backend G1 回执确认：401 为 HTTP 401 且业务 `code=401`，403 为 HTTP 403 且业务 `code=403`，响应
均包含 `success/code/message/data`。前端当前拦截器只检查 `error.response.status`：
`src/api/index.ts:30-35` 能处理 HTTP 401/403，但成功收到 `success=false, code=401/403` 时只走通用
错误分支，不能对业务 401 执行清理 Token 和跳转登录。

因此 G1-02 前端部分暂不通过。仓库内没有覆盖 request interceptor 的运行时测试；需要 Claude Code
补齐业务 code 处理、403 保持登录态的测试，再由 Frontend Codex 复验。当前不修改业务源码，因为
Gate 0/1 尚未由 PM 关闭，且本角色本轮只提交消费回执和验收状态。

## 4. 阻塞与接收动作

- `HANDOFF-HASH-MISMATCH`：PM 仍需建立后端源 `44cbe7...`、脱敏交接声明 `0057e69...` 与消费文件
  的唯一映射；前端已停止消费 `87e122...` 副本。
- `FRONTEND-BUSINESS-401-403`：Claude Code 补齐响应体错误码处理和测试；Frontend Codex 复验 HTTP
  状态、业务 code、Token 清理、登录跳转和 403 保持登录态。
- `FRONTEND-NODE-DEFAULT`：用户环境需修复 `nvm-desktop` 默认版本；本回执保留临时 PATH 验证证据。

当前不生成正式客户端、不启动首轮真实 API 联调、不修改 `finalReleaseStatus`。
