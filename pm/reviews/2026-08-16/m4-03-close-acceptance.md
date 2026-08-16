# M4-03 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-16
> **任务：** M4-03 凭据与环境收口
> **任务书：** `pm/requirements/2026-08-13/m4-03-credential-hardening-task.md`
> **执行回执：** `handoff/backend-to-frontend/2026-08-13/m4-03-credential-hardening-report.md`
> **复核签署：** 后端评审（B-Review，原 Backend Codex），2026-08-13
> **验收结论：** ✅ **通过，M4-03 关闭**

## 关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 1 | grep 核验无明文凭据（命令与输出 + 清理提交哈希） | 凭据外部化提交 `2c95730`/`0fa9f41`、后续修复 `45c209f`；清理后 grep 零命中 | ✅ |
| 2 | 配置优先级文档与端口策略文档存在 | `docs/backend/2026-08-13-m4-03-config-precedence.md`、`m4-03-port-policy.md` | ✅ |
| 3 | 回执含凭据轮换完成记录引用（用户/运维提供） | 用户 2026-08-13 完成 Nacos/Redis/MySQL/MinIO 凭据轮换；回执 §4 记录 | ✅ |
| 4 | 回执含原始命令输出与提交哈希，后端评审复核签署 | 签署 2026-08-13（工作底稿 `designs/backend/2026-08-13/m4-03-credential-hardening-review-workpaper.md`） | ✅ |

## 关键核验

- **明文凭据清理**：三启动脚本 Nacos 用户名/密码环境变量化（缺失时阻止启动）；`start-subject.ps1` 移除 `REDIS_PASSWORD` 强制校验（Redis 以 Nacos 为源）。
- **Nacos 上收**：三个 `*-dev.properties` 已上收全部敏感配置；静态 + 运行时冒烟验证通过（Auth 启动 19.5s，登录 code=200）。
- **凭据轮换**：由用户执行（运维侧，非后端职责），轮换后 Nacos 配置同步新值并双重核验。
- **API 快照**：SHA-256 未变（`7576e28a…`，43/43），示例脱敏为既有状态。

## 已知限制（验收知悉，不阻塞关闭）

1. Nacos 配置持有运行凭据，轮换需在 Nacos 控制台同步（不在仓库范围）。
2. 启动依赖 `NACOS_USERNAME`/`NACOS_PASSWORD` 环境变量。
3. 签署备注：Subject 在轮换后 Nacos 配置下的独立启动验证未见明确记录（OSS 已由 M4-02 §8 覆盖）——**列为 M4 后续验证补充项**（M4-06 或 Gate 4 前由后端实现补记，不阻塞本任务关闭）。

## 备注

- 无阻塞项；任务书 §4 关闭条件 1-4 全部满足。
- 验收结论写入 `status/pm.json`（M4-03 验收通过）；Subject 启动验证补充项登记在案。
