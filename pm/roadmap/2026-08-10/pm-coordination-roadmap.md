# CoderClub PM 跨项目协调路线图

> **路线图角色：** PM / 跨项目协调 Codex
>
> **生效基线：** `origin/main@ae0c8ad960d7bab4e931b69cf65bfd261d989b53`
>
> **定位：** 本文件是当前唯一的 PM 协调路线图。`designs/backend/roadmap/` 中的 3 份文件继续作为后端历史计划保留，不再单独作为跨项目当前进度源。

## 目标

把后端已经完成的 M1-M3 能力转化为可供前端安全消费、可由 PM 验收、可追溯到源提交的跨项目交付。路线图先解决契约和状态事实源，再推进 M4 安全质量收口和前端业务实现。

## Gate 0：证据与基线归一化

**状态：开发契约快照已验收；发布仍受 Gate 1 阻塞。**

| 事项 | Owner | 交付物 | 关闭条件 |
| --- | --- | --- | --- |
| 唯一 API 文件身份 | PM + Backend | 契约基线提案 | 源路径、源提交、源 SHA-256、交接文件、交接 SHA-256 一一对应 |
| C0/C1 版本关系 | PM + Frontend | C0/C1 回执 | 解释 `7e3f77...`、`3161c41...` 和当前主线提交的关系 |
| API 副本治理 | PM | ADR-0001 和 `api/coderclub-openapi.json` 快照元数据 | 已批准受控开发快照；后端源仍为运行时权威，快照不等于发布契约 |
| 状态文件一致性 | PM | `status/pm.json`、`status/backend.json`、`status/frontend.json`、`status/sync-manifest.json` 的审计记录 | 开发快照映射可复核；`releaseStatus` 与 `finalReleaseStatus` 仍为未发布 |

## Gate 1：契约消费阻塞项

**状态：Gate 1 全部验收通过并正式关闭（G1-01 至 G1-05，2026-08-13 关闭 G1-04）；发布仍受 Gate 2（M4）与 PM 发布验收约束。**

| 事项 | Owner | 验收证据 |
| --- | --- | --- |
| 14 个未声明安全策略操作 | Backend 提供运行时矩阵，PM 审核 | 每个操作明确匿名、登录或角色/权限；OpenAPI 与运行时一致 |
| POST/PUT/DELETE 兼容端点 | PM 决策，Backend 说明兼容原因 | 正式方法、兼容期限、角色和移除条件 |
| 401/403 语义 | Backend + Frontend | HTTP 状态、业务 code、响应结构和前端处理方式一致 |
| 登录、密码和 Token 语义 | Backend | `/auth/login`、`/auth/user/info`、`/auth/user/password` 的请求和响应样例 |
| 分页一致性 | Backend | `subjectType=99` 等无结果、单页、多页复现和修复测试 |

Gate 1 已关闭（2026-08-13）。Frontend 可以基于 PM 批准的快照推进已确认范围的开发并进入正式联调，但不能视为发布放行；发布仍受 Gate 2（M4）与 PM 发布验收约束。

## Gate 2：M4 后端安全与质量收口

**状态：后端报告已列出，PM 尚未拆解验收。**

优先顺序：

1. 角色和权限矩阵：明确普通用户与管理员对 Subject、Auth 管理端点的 401/403 行为。
2. OSS 访问控制：明确上传、URL 查询、调试端点是否开放；去除“接口可用但默认匿名”的不确定性。
3. 分页查询修复：统一 count 与 list 的过滤条件，补 API 层回归测试。
4. 凭据与环境收口：轮换历史暴露凭据，清理启动脚本明文，统一 Nacos/环境变量优先级，记录 <subject-port>/<subject-alt-port> 和 <mysql-probe-port>/<mysql-port> 的标准策略。
5. 测试质量门禁：覆盖率基线、集成测试方案、CI/CD 执行命令和失败处理。
6. 非法请求体处理：确认非法 UTF-8 是否归类 400，并补异常映射测试。

Gate 2 的每一项必须有后端提交哈希、测试命令、结果和已知限制；仅修改报告不视为完成。

## Gate 3：Frontend 首轮消费与验收

**状态：开发快照已就绪，Gate 1 已关闭；等待 Gate 2（M4）收口后启动正式联调。**

Frontend 依次执行：

1. 固定 `apiContractCommit=1a2aff823b3b941b6d9c0ccd8a29f40545d3eb17` 和 SHA-256 `87e122...`，验证 `npm run api:check`。
2. 完成认证、用户信息和登出状态流转。
3. 完成角色/权限树、动态路由和 401/403 处理。
4. 完成分类、标签、题目分页、详情、四种题型和 OSS 上传。
5. 对每个列表实现 loading、空、错误、重试和重复提交保护。
6. 回传实际服务地址、已验证接口清单、失败请求、响应和复现条件。

Frontend 不自行推断重复方法或权限；所有契约疑问进入 `proposals/frontend/`，由 PM 协调 Backend 回执。

## Gate 4：PM 发布前验收

发布前必须同时满足：

- API 唯一基线已确认，前端消费 SHA-256 与交接 SHA-256 一致。
- M4 P0/P1 项目关闭，或有明确的 PM 书面例外和到期日。
- 后端与前端验收记录分别包含提交哈希、命令、结果和环境。
- `status/sync-manifest.json` 反映真实同步关系；`releaseStatus` 仍由 PM 控制。
- `finalReleaseStatus` 只有在 PM 明确授权后才可变更。
- 没有未解释的契约方法、鉴权或分页口径差异。

## 角色分工

| 角色 | 负责 | 不负责 |
| --- | --- | --- |
| PM Codex | 基线裁决、优先级、提案协调、验收和发布状态 | 后端/前端业务代码 |
| Backend Codex | 后端实现、运行时证据、契约来源和 M4 修复 | 直接改 `api/` 或替 PM 发布 |
| Frontend Codex | 前端实现、消费验证、问题复现和前端验收 | 自行裁决契约或修改权威 API |

## 停止条件

出现以下任一情况时暂停跨项目实现：

- 契约 SHA-256 或来源提交无法唯一确认。
- 同一路径的正式 HTTP 方法未确定。
- 鉴权矩阵没有覆盖所有操作。
- 分页 `total`/`list` 仍然不一致且没有例外批准。
- 前端工作区的 Node/test 基础环境未恢复，无法形成真实验证结果。
