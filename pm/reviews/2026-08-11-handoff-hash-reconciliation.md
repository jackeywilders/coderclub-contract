# API 交接哈希映射收口记录

> **处理角色：** PM / 跨项目协调 Codex
>
> **日期：** 2026-08-11
>
> **处理事项：** `HANDOFF-HASH-MISMATCH`

## 核验结果

PM 对后端运行时源和交接仓库实际快照重新计算 SHA-256：

| 资产 | 提交 | SHA-256 | 判定 |
| --- | --- | --- | --- |
| 后端运行时源 `CoderClub/docs/api/coderclub-openapi.json` | `e80aaf697fecd350ad478d8fed67eb81fdf45325` | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` | 运行时权威 |
| 交接仓库快照 `api/coderclub-openapi.json` | `1a2aff823b3b941b6d9c0ccd8a29f40545d3eb17` | `87e122b545ed529edc167b80279869205440be84e12c4407850dfa1d4ff2166b` | PM 批准的开发快照 |
| 历史回执声明 | 无 | `0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c` | 过期/错误声明，已取代 |

源文件与快照的结构化差异仍为 14 处，全部是密码和 Token 示例值脱敏；路径、方法、字段、
Schema、鉴权结构和 47 个操作没有差异。

## PM 决策

后续跨项目开发统一使用以下唯一映射：

`e80aaf6 → 44cbe7... → 1a2aff8/api/coderclub-openapi.json → 87e122...`

`0057e...` 仅作为历史声明保留，不再作为当前交接副本或消费基准。已同步
`status/backend.json` 与 `status/frontend.json`，并移除 `HANDOFF-HASH-MISMATCH` 阻塞项。

本次不修改后端运行时源、交接仓库 API 快照或 `status/sync-manifest.json`；同步清单中已有相同
的 `historicalDeclaredSha256` 取代标记。`releaseStatus` 和 `finalReleaseStatus` 继续为
`not-published`。
