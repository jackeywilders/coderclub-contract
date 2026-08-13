# G0/G1 当前验收状态更新

> **维护角色：** PM / 跨项目协调 Codex
>
> **日期：** 2026-08-11（G1-03 状态于 2026-08-12 更新，G1-04 状态于 2026-08-13 更新）
>
> **当前 PM 主线：** `origin/main@2be39aff861b2e563681f9aadf2b11feb737f6b3`

## Gate 0

G0-01 至 G0-06 已全部通过开发范围验收。G1-03 同步后的 `api/coderclub-openapi.json` 当前批准映射为：

`87d2b72 → 7576e2... → 99367ea/api/coderclub-openapi.json → 9a97c0...`

历史 `87d2b72 → 7576e2... → 73cc5b0 → 5a8919...`、`6c1a95b → cf6998... → 21f6f64 → 007ca1...`、`e80aaf6 → 44cbe7... → 1a2aff8 → 87e122...` 与 `0057e...` 声明已不再作为当前快照依据。Gate 0 关闭不等同于发布，
`releaseStatus` 和 `finalReleaseStatus` 继续为 `not-published`。

## Gate 1

| 项目 | 当前状态 | 说明 |
| --- | --- | --- |
| G1-01 | accepted | 鉴权矩阵及运行时依据已复核 |
| G1-02 | accepted | 后端 401/403 证据、前端业务 code 处理和回归测试已完成 |
| G1-03 | accepted | 已正式关闭（2026-08-12）：后端移除四个旧 POST、PM 重建并复核开发快照、前端基线更新为 43 endpoints 并完成消费验证；见 `pm/reviews/2026-08-12/g1-03-close-acceptance.md` |
| G1-04 | accepted | 已正式关闭（2026-08-13）：死代码清理 `fad2312` + 真实数据库九场景复核 + Backend Codex 签署；见 `pm/reviews/2026-08-13/g1-04-close-acceptance.md` |
| G1-05 | accepted | 用户已确认默认 Node/npm 入口，前端验证证据已完成 |

Gate 1 已于 2026-08-13 全部验收通过并正式关闭（G1-01 至 G1-05 均 accepted），不批准发布或正式联调以外的发布动作。G1-03 的旧 POST 兼容策略已由 PM 明确拒绝，
后端实现已完成；后端细粒度权限矩阵（`G1-02-FINE-GRAINED-PERMISSION`）移交 M4 后续范围，不重新打开已关闭的 G1-02。
