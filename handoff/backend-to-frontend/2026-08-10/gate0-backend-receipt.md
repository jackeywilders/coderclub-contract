# Gate 0 后端回执：API 来源与脱敏映射

> 回执角色：Backend Codex
> 回执目标：G0-01、G0-02
> 状态：后端证据已完成，待 PM 汇总关闭 Gate 0

## 1. 唯一来源确认（G0-01）

| 项目 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClub` |
| 来源分支 | `main` |
| 来源提交 | `e80aaf697fecd350ad478d8fed67eb81fdf45325` |
| 权威源文件 | `docs/api/coderclub-openapi.json` |
| OpenAPI 版本 | `3.0.3` |
| 文档版本 | `1.0.0` |
| 路径数量 | `45` |
| 操作数量 | `47` |
| 源 SHA-256 | `44cbe709887e840174d1bdd02f32a423561013e0622b81e76c9346d2e87e265a` |

核验命令：

```powershell
git -C G:\Dev\backend\Club\CoderClub show -s --format="%H %s" e80aaf697fecd350ad478d8fed67eb81fdf45325
Get-FileHash -Algorithm SHA256 G:\Dev\backend\Club\CoderClub\docs\api\coderclub-openapi.json
Get-Content -Raw G:\Dev\backend\Club\CoderClub\docs\api\coderclub-openapi.json | ConvertFrom-Json
```

结果：提交、路径、SHA-256、JSON 可解析性、`openapi=3.0.3`、`info.version=1.0.0` 和 `45/47` 统计均与本回执一致。

## 2. 源文件与现有交接副本关系（G0-02）

本回执只核验交接仓库中已有的 `api/coderclub-openapi.json`，没有新增、修改或重新发布 `api/` 文件。现有副本 SHA-256 为：

`0057e69c4deb3e769e191fb319a16f00d4d0fe3eec0b0fc3c218c8e55e4ae20c`

已复核的确定性转换命令如下：

```powershell
$source = Get-Content -Raw G:\Dev\backend\Club\CoderClub\docs\api\coderclub-openapi.json
$source.Replace('123456','<password>') `
    .Replace('newpassword123','<new-password>') `
    .Replace('newSecurePass456','<new-password>') `
    .Replace('3f8a1c2d9b4e6f7a5c1d8e2f9b4a6c7d','<token>') `
    .Replace('7d2c4f6a8b1e3d5c7f9a2b4e6c8d1f3a','<token>') `
    | Set-Content -NoNewline -Encoding UTF8 .\api\coderclub-openapi.expected.json
```

对照结果：将上述输出与现有 `api/coderclub-openapi.json` 逐字比较为相同；JSON 语义差异共 14 处，全部是密码或 Token 示例值替换。路径、HTTP 方法、请求字段、响应字段、Schema、全局安全策略和接口数量没有差异。

## 3. 治理说明与接收方动作

- 后端项目中的 `docs/api/coderclub-openapi.json` 是权威来源；交接仓库副本不是权威来源。
- 当前交接治理规则禁止 Backend 继续写入 `api/`，因此本次不更新该副本，也不把它标记为已发布契约。
- PM 需要完成 G0-03/G0-05/G0-06：决定现有副本的治理处置，建立 `source commit → source SHA-256 → handoff reference → frontend SHA-256` 唯一映射，并保持 `finalReleaseStatus=not-published`。
- Frontend 在 PM 关闭 Gate 0 前不得把现有副本作为已确认发布契约；接收时应重新核验源文件和自身消费文件 SHA-256。

## 4. 已知限制

此前文档曾使用 `085fe08...` 作为 API 来源提交；本回执已统一改以当前后端 `main@e80aaf697fecd350ad478d8fed67eb81fdf45325` 为来源。C0 哈希 `7e3f77...` 属于交接仓库基线，不作为后端项目提交使用。
