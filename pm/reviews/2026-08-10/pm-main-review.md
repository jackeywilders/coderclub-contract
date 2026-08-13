# CoderClub PM 主线审查问题清单

> **审查基线：** `origin/main@ae0c8ad960d7bab4e931b69cf65bfd261d989b53`
>
> **审查角色：** PM / 跨项目协调 Codex
>
> **状态说明：** 本文件记录当前主线的审查发现和责任分配，不直接修复问题。

> **后续决策说明：** 本文件记录的是 ADR-0001 之前的审查状态。关于 `api/coderclub-openapi.json` 副本治理、契约映射和同步清单的旧阻塞，已由 `docs/adr/0001-development-contract-snapshot.md` 和 `pm/reviews/2026-08-10/gate-0-1-pm-acceptance.md` 取代；Gate 1 和 M4 遗留项仍然有效。

## 严重级别

- **P0：** 阻断契约消费、发布或治理有效性，必须先处理。
- **P1：** 影响前后端实现正确性或验收完整性，需要在当前交付批次关闭。
- **P2：** 不立即阻断，但会造成维护、审计或后续迭代成本。

## P0

### PM-001：后端角色将 OpenAPI 副本写入了禁止路径

- **证据：** `api/coderclub-openapi.json` 出现在 `origin/main`；`AGENTS.md` 的协作约定和 `docs/INDEX.md` 均规定交接仓库不复制 OpenAPI，Backend Codex 也明确禁止写入 `api/`。
- **影响：** 权威 API 与交接副本的责任边界失效；前端可能把未确认副本当作唯一契约，PM 无法仅依靠目录结构判断文件来源和权限。
- **责任：** PM 负责治理裁决，Backend 负责解释生成来源，Frontend 负责暂停消费直到唯一基线确认。
- **当前动作：** 本次不删除或改写 `main` 中的文件；先在提案中决定是调整治理规则允许受控副本，还是恢复“只存引用/摘要”的原设计。
- **验收条件：** 治理规则、目录用途、API 文件来源和所有状态文件对同一策略一致；未经授权不得把副本作为已发布契约。

### PM-002：契约身份存在多条互相冲突的链路

- `designs/backend/2026-08-07/api-contract-baseline.md` 和 `handoff/backend-to-frontend/2026-08-07/api-contract-handoff.md` 声明源代码提交为 `085fe08...`、C0 为 `7e3f77...`、交接副本 SHA-256 为 `0057e69...`。
- `status/backend.json` 把最近提交写为 `e80aaf...`，并把 `7e3f77...` 作为 C0 基线。
- `status/frontend.json` 的 C1 提交为 `3161c41...`，但前端实际文件 SHA-256 为 `87e122...`，期望值为 `0057e69...`。
- `status/sync-manifest.json` 的 `backendCommit`、`frontendCommit`、`apiContractCommit` 仍为空。
- **影响：** 前端无法判断应导入哪份文件；PM 无法用提交哈希重建“后端源 → 交接副本 → 前端消费副本”的链路。
- **责任：** PM 牵头，Backend 提供源文件和源提交，Frontend 提供实际消费文件及校验结果。
- **验收条件：** 形成一张唯一映射：`backend source commit → source SHA-256 → handoff commit → handoff SHA-256 → frontend consumed commit/SHA-256`，并由三方回执。

### PM-003：同步清单与实际主线状态相互矛盾

- `status/sync-manifest.json` 仍为 `releaseStatus=not-published`、`finalReleaseStatus=not-published`、三个提交字段为空，并写着“没有复制 OpenAPI 文件”。
- 当前主线已经有 OpenAPI 文件，`status/backend.json` 已写成 `contract-baseline-published`，`status/frontend.json` 也已进入 `design-ready-pending-contract-reconciliation`。
- **影响：** 状态文件不能作为协调事实源；不同角色会得到不同的“是否已发布、是否可消费”结论。
- **责任：** PM。
- **当前动作：** 本次保持发布状态为未发布；在契约身份确认后，更新同步字段和阻塞项，但不以同步文件替代提案、评审或验收。
- **验收条件：** `sync-manifest` 描述真实同步状态，`finalReleaseStatus` 仍只有 PM 明确授权才能变更。

## P1

### PM-004：OpenAPI 安全策略不覆盖 M3 报告声称的完整范围

- **证据：** 当前 OpenAPI 47 个操作中 26 个声明 `Authorization`、7 个声明匿名、14 个安全策略未声明。
- **影响：** 前端无法从契约建立完整的登录、角色和 403 行为；“M3 已补齐 14 个未受保护端点”的代码整改结论没有同步反映到契约文件。
- **责任：** Backend 提供运行时实际鉴权矩阵，PM 评审并固化，Frontend 按确认矩阵实现路由和请求拦截。
- **验收条件：** 每个操作都明确 `anonymous`、`login` 或 `role/permission`；HTTP 401、业务 `code=401` 和 403 的处理方式有测试或运行时证据。

### PM-005：历史兼容 HTTP 方法没有唯一生产决策

- **证据：** `/subject/category/update`、`/subject/category/delete`、`/subject/label/update`、`/subject/label/delete` 等操作同时保留 POST 与 PUT/DELETE 形式；前端问题单要求确认正式方法和兼容端点。
- **影响：** 前端可能调用已不应继续使用的 POST；网关、权限、审计和接口测试会出现双路径覆盖不一致。
- **责任：** PM 决策，Backend 提供兼容依据，Frontend 只实现确认后的正式方法。
- **验收条件：** 每个重复操作记录正式方法、兼容方法、鉴权角色、保留截止版本和移除条件；前端首轮联调清单只使用正式方法。

### PM-006：分页 `total` 与 `list` 过滤口径不一致

- **证据：** M3 联调附录 B 以 `subjectType=99` 复现 `data.list=[]` 但 `data.total=23`；API 修复验收报告和后端状态均将该项移交 M4。
- **影响：** 前端分页器可能显示非零总数但当前页为空，翻页、空状态和筛选结果都会误导用户。
- **责任：** Backend 修复 `countByCondition` 与分页查询的过滤条件；Frontend 保留复现参数和响应，PM 负责验收。
- **验收条件：** 对每个过滤字段执行“列表条数、total、totalPages”一致性测试；至少覆盖无结果、单页和多页场景。

### PM-007：M4 安全与质量范围尚未成为可执行任务

- **证据：** M3 完工报告明确移交角色/权限矩阵、403 测试、OSS 访问控制、覆盖率门禁、Docker 集成测试、CI/CD、凭据外置化和非法 UTF-8 处理等事项，但当前 `pm/roadmap/` 只有 `.gitkeep`。
- **影响：** M4 只是报告中的集合，不具备负责人、依赖、验收标准和停止条件；后端可能继续以 M3“全部通过”作为完成信号。
- **责任：** PM 建立路线图，Backend 拆解实现与测试，Frontend 提供权限和错误状态验收。
- **验收条件：** 每项有 owner、输入提交、交付文件、验证命令、风险和关闭证据。

### PM-008：后端报告引用了当前主线未收录的历史路径

- **证据：** 多份报告引用 `docs/backend/roadmap/`、`docs/backend/milestones/`、`docs/reviews/` 和 `.superpowers/` 路径；当前 `origin/main` 文件树只有 `designs/backend/`、`acceptance/backend/` 等交接路径。
- **影响：** 复核者无法从交接仓库直接打开报告引用的设计、计划和审查原文；提交哈希也属于外部后端仓库，无法在本仓库验证。
- **责任：** PM 统一引用策略；Backend 在交接材料中补充外部仓库、分支、提交哈希和不可复制文件的定位说明。
- **验收条件：** 每个引用要么在交接仓库存在，要么明确 `repository/path/commit`；禁止使用无法定位的相对链接作为唯一证据。

### PM-009：运行环境存在未收口的凭据和配置漂移

- **证据：** 联调附录记录 Nacos 中 Auth Redis 密码陈旧，需要环境变量覆盖；启动脚本历史存在明文凭据，旧值仍在 Git 历史；Subject 需要 <subject-alt-port> 替代 <subject-port>；MySQL 使用 <mysql-port> 而探测默认 <mysql-probe-port>。
- **影响：** 本地联调成功不等于标准环境可复现；凭据轮换、服务端口和启动方式可能让前端或 CI 得到不同结果。
- **责任：** Backend 负责配置安全和启动契约，PM 负责把环境前置条件纳入验收，Frontend 记录实际服务地址。
- **验收条件：** 凭据全部外置并完成轮换，启动命令参数化，标准端口/覆盖端口有明确规则，CI 或容器环境可重跑。

## P2

### PM-010：PM 目录尚未承担 PM 事实源职责

- **证据：** `pm/roadmap/`、`pm/requirements/`、`pm/reviews/`、`pm/reports/` 在主线中只有 `.gitkeep`。
- **影响：** 当前项目所有路线图和完工报告由 Backend 角色主导，缺少跨项目优先级、决策、阻塞和发布裁决。
- **当前动作：** 本次在 PM worktree 补齐主线汇总、审查问题和协调路线图；不修改 `main`。

### PM-011：后端路线图存在历史版本叠加，没有唯一当前版本

- **证据：** `2025-07-30` P0-P3 推进计划、`2026-07-28` 三次 Iteration 设计、`2026-07-31` M1-M4 执行计划同时存在；其中旧计划把 Subject/OSS 鉴权放在 P0，新计划将细粒度安全能力放到 M4。
- **影响：** 任务优先级、里程碑名称和完成标准容易被不同角色引用；“M3 完成”可能被误读成“安全达标”。
- **责任：** PM。
- **验收条件：** 保留历史文件，但新增唯一的 PM 当前路线图；每个历史文件标记为 archival，并指向当前路线图。

### PM-012：报告完成数字没有统一统计口径

- **证据：** M2 报告使用 27/27，M3 初始联调记录静态汇总使用 56，M3 完工报告最终使用 79；不同文档还引用不同基线提交和测试范围。
- **影响：** 数字本身可能分别正确，但不注明模块、时间、命令和是否包含整改，就无法作为项目级质量指标。
- **验收条件：** 所有测试数字附命令、基线、时间、模块范围和是否复测；PM 只汇总可比较的指标。

## PM 总体裁决

当前不批准前端基于现有 C1 文件生成客户端，不批准将 `finalReleaseStatus` 改为已发布，也不批准删除兼容端点。先执行 `pm/roadmap/2026-08-10/pm-coordination-roadmap.md` 的 Gate 0 和 Gate 1，再决定 M4 与前端首轮联调的并行边界。
