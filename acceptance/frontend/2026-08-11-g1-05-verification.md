# G1-05 前端验证门禁复核报告

> **验收角色：** Frontend Codex
> **复核日期：** 2026-08-11
> **交接仓库分支：** `codex/frontend-design`
> **前端项目：** `G:/Dev/backend/Club/CoderClubFront`

## 1. 复核结论

**G1-05 部分通过，提交 PM 审核。** Node/npm 实体版本、前端测试和 API 契约校验均已在本次复核中真实执行并通过；但当前 Codex 受限终端无法证明默认 `node`/`npm` shim 可直接使用，因此暂不把默认环境门禁标记为完全关闭。

## 2. 验证环境与命令

已确认本机安装目录 `G:/Dev/env/nodejs/versions/22.14.0` 存在可执行的 `node.exe` 和 `npm.cmd`。本次在前端项目目录临时将该目录置于 `PATH` 首位后执行：

```powershell
node --version
npm --version
npm test
npm run api:check
```

结果如下：

| 检查项 | 结果 |
| --- | --- |
| Node | `v22.14.0` |
| npm | `10.9.2` |
| `npm test` | 通过，10/10，0 失败、0 跳过 |
| `npm run api:check` | 通过，OpenAPI 3.0.3，47 个操作，无契约变化 |
| API SHA-256 | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |

## 3. 默认入口限制

`C:/Users/Sakura/.nvmd/default` 已记录 `22.14.0`，但 Codex 沙箱将当前用户目录映射为 `C:/Users/CodexSandboxOffline`。因此 `C:/Users/Sakura/.nvmd/bin/node.exe` 运行时读取了不存在的 `C:/Users/CodexSandboxOffline/.nvmd/versions`，并报告默认 Node 版本未设置。

该错误发生在 Codex 终端的 nvm shim 环境层；使用实际 Node 22 安装目录执行项目命令没有失败。PM 如需关闭默认入口门禁，应在用户自己的 CMD 或 PowerShell 中重新确认：

```powershell
nvmd current
node --version
npm --version
where.exe node
where.exe npm
cd G:\Dev\backend\Club\CoderClubFront
npm test
npm run api:check
```

## 4. PM 审核请求

请依据用户终端的默认入口命令结果，将 `G1-05-FRONTEND-NODE-DEFAULT` 判定为关闭或继续保留。除默认 shim 证据外，本报告所列 Node/npm 版本、测试结果和 API 哈希校验均已通过。
