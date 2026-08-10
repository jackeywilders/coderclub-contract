# Gate 0/1 PM 验收记录

> **验收角色：** PM / 跨项目协调 Codex
>
> **验收主线：** `main@4551f0fd016b7363738d3571d5a76e261701b547`
>
> **验收范围：** Backend G0/G1 回执、Frontend G0/G1 消费回执、分页验收记录和四份状态文件。

## 1. 总体结论

**G0：开发契约快照验收通过，发布门禁未关闭。**

**G1：部分验收通过，未关闭。**

**发布结论：** `releaseReady=false`；`releaseStatus` 和 `finalReleaseStatus` 均保持 `not-published`。Frontend 可以基于已批准的开发契约快照推进后续开发，但 G1 未关闭前不批准发布或依赖未确认方法的正式联调。

本次验收确认了有效消费链路：

```text
Backend main@e80aaf6
  └─ docs/api/coderclub-openapi.json
     └─ SHA-256 44cbe7...
        └─ PM-approved handoff snapshot 1a2aff8 / SHA-256 87e122...
           └─ Frontend may consume the snapshot for subsequent development
```

快照与后端源的结构化比较差异共 14 处，全部是密码或 Token 示例值脱敏；路径、方法、字段、Schema 和鉴权结构没有差异。Backend 历史回执声明的 `0057e69...` 与当前跟踪副本不一致，已作为历史声明保留；本次以已复核的实际快照 `87e122...` 作为后续开发引用，并在 ADR-0001 和同步清单中固定映射。

## 2. 复核的来源与提交

| 证据 | 提交/哈希 | PM 复核结果 |
| --- | --- | --- |
| Backend API 来源 | `e80aaf697fecd350ad478d8fed67eb81fdf45325`；源 SHA-256 `44cbe7...` | 路径、OpenAPI 3.0.3、45 路径、47 操作一致 |
| Backend G0 回执 | 交接主线提交 `d398bbc9405e338880fe0c61cce97a9caa46807e` | 来源与脱敏映射已记录 |
| Backend G1 回执 | 后端验证提交 `06397f...`、`08cd88...`；交接主线包含于 `d398bbc...` | 鉴权、方法、分页证据已记录 |
| Frontend 来源 | `main@cb62823f5944d4f544a3f11da8685900a5d8cfb4` | 回执明确消费后端权威源 |
| Frontend G0/1 回执 | 交接主线提交 `e6849cc231dae7d043166b8a7bf6ad20bced78a1` | 哈希校验、Node/npm 结果和阻塞项已记录 |
| 当前交接主线 | `4551f0fd016b7363738d3571d5a76e261701b547` | Backend 与 Frontend 回执均已进入 main |

## 3. Gate 0 验收

| 项目 | 判定 | 依据与遗留项 |
| --- | --- | --- |
| G0-01 唯一源文件身份 | 通过 | Backend 提供 `e80aaf6`、源路径和 `44cbe7...`；JSON 统计为 45/47 |
| G0-02 脱敏映射关系 | 通过证据项 | Backend 提供确定性替换命令和 `0057e69...` 声明；未重新发布 `api/` 副本 |
| G0-03 副本治理 | 通过（开发范围） | ADR-0001 批准 `api/coderclub-openapi.json` 作为后续开发权威快照；后端源仍是运行时权威，快照不等于发布契约 |
| G0-04 Frontend 消费来源 | 通过 | Frontend 已验证后端源 SHA-256 `44cbe7...`；后续可按同步清单引用已批准快照 `87e122...` |
| G0-05 唯一消费映射 | 通过（开发范围） | 已固定 `e80aaf6 → 44cbe7... → 1a2aff8/api/coderclub-openapi.json → 87e122...`；`0057e69...` 标记为历史声明 |
| G0-06 状态元数据 | 通过（开发范围） | `status/sync-manifest.json` 已记录源提交、源哈希、快照提交、快照哈希、语义差异和同步时间；发布字段仍为未发布 |

### Gate 0 判定

G0 作为“开发契约快照”已关闭：来源、快照、哈希映射和治理状态均可复核。G0 不等同于发布门禁；`finalReleaseStatus` 仍为 `not-published`，G1 遗留项继续阻塞发布和正式联调。

## 4. Gate 1 验收

| 项目 | 判定 | 依据与遗留项 |
| --- | --- | --- |
| G1-01 47 操作鉴权矩阵 | 通过 | `anonymous=7`、`login=36`、`role/permission=4`，每项有控制器依据 |
| G1-02 401/403 语义 | 部分通过 | Backend 的 HTTP/code/响应结构和 Auth/Subject 测试通过；Frontend 尚未处理业务体 `code=401/403` |
| G1-03 正式 HTTP 方法 | 部分通过 | PUT/DELETE 正式方法已确认；POST 兼容端点的截止版本/日期未确定 |
| G1-04 分页一致性 | 代码级通过 | 无结果、单页、多页和 41 项 Controller 测试证据通过；真实 MySQL 等价请求尚未复核 |
| G1-05 Frontend 验证门禁 | 部分通过 | 临时 PATH 下 `npm run api:check` 和 `npm test` 通过；默认 `nvm-desktop` 仍未配置 |

### Gate 1 判定

Backend 的鉴权矩阵和分页修复证据已通过 PM 复核，但 Frontend 业务 401/403、POST 兼容期限和默认 Node 环境仍未关闭，因此 **Gate 1 不关闭**。

## 5. 后续关闭动作

1. Claude Code 补充 Frontend 响应体 `code=401/403` 处理和拦截器测试；Frontend Codex 重新复验。
2. PM 为 POST 兼容端点补充保留截止版本/日期和移除条件。
3. Frontend 按 `apiContractCommit=1a2aff8` 和快照 SHA-256 `87e122...` 固定后续开发输入，并继续记录消费验证。
4. Frontend 或用户环境修复 `nvm-desktop` 默认 Node 版本，并重新执行默认命令。
5. 按路线图继续推进 M4 细粒度权限、OSS 访问控制、凭据和质量门禁。

## 6. 验收边界

本次 PM 验收基于主线回执、提交引用、JSON 解析、文件哈希和文档证据；未在本次验收中重新启动 Nacos、Redis、MySQL 或三服务真实环境。分页真实数据库请求、Frontend 业务错误码处理和默认 Node 环境仍是明确的未关闭项。
