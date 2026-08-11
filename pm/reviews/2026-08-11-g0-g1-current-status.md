# G0/G1 当前验收状态更新

> **维护角色：** PM / 跨项目协调 Codex
>
> **日期：** 2026-08-11
>
> **当前 PM 主线：** `origin/main@d627c3e64b24add05cb958fc7990208f62d9807d`

## Gate 0

G0-01 至 G0-06 已全部通过开发范围验收。`api/coderclub-openapi.json` 的批准映射为：

`e80aaf6 → 44cbe7... → 1a2aff8/api/coderclub-openapi.json → 87e122...`

历史 `0057e...` 声明已标记为过期，不再作为当前快照依据。Gate 0 关闭不等同于发布，
`releaseStatus` 和 `finalReleaseStatus` 继续为 `not-published`。

## Gate 1

| 项目 | 当前状态 | 说明 |
| --- | --- | --- |
| G1-01 | accepted | 47 个操作鉴权矩阵及运行时依据已复核 |
| G1-02 | accepted | 后端 401/403 证据、前端业务 code 处理和回归测试已完成 |
| G1-03 | open | 正式 PUT/DELETE 已确定，POST 兼容截止版本/日期仍待 PM 决策 |
| G1-04 | partial | 代码级分页修复和测试已通过，真实数据库复核仍待完成 |
| G1-05 | accepted | 用户已确认默认 Node/npm 入口，前端验证证据已完成 |

Gate 1 当前保持 partial，不批准发布或正式联调。后端细粒度权限矩阵属于 M4 后续范围，
不重新打开已关闭的 G1-02。
