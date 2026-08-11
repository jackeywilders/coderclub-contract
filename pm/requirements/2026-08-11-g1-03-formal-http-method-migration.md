# G1-03 正式 HTTP 方法迁移实施计划

> **面向 AI 代理的工作者：** 必须先读取本仓库的 `AGENTS.md`、`CLAUDE.md` 和 `docs/INDEX.md`。契约变更先由 Backend Codex 写入 `proposals/backend/` 并获得 PM 确认，再由 Claude Code 后端执行后端实现。Backend/Frontend Codex 和 Claude Code 后端/前端均不得直接修改交接仓库 `api/` 快照。

**目标：** 将分类、标签的更新和删除操作统一为唯一正式的 PUT/DELETE 方法，移除对应旧 POST 映射，完成后端源 API、前端基线和 PM 开发契约快照的同步，关闭 G1-03。

**架构：** 后端运行时 Controller 和 `CoderClub/docs/api/coderclub-openapi.json` 是运行时契约来源；PM 批准的交接仓库 `api/coderclub-openapi.json` 是跨项目开发快照。旧 POST 不保留兼容路由，分类/标签业务能力由正式 PUT/DELETE 路由承载。

**技术栈：** Spring Boot / Spring MVC、Sa-Token、JUnit 5、MockMvc、OpenAPI 3.0.3、Vue/TypeScript、npm。

---

## 决策边界

### 纳入范围

| 旧操作 | 正式操作 | 请求形态 |
| --- | --- | --- |
| `POST /subject/category/update` | `PUT /subject/category/update` | JSON body，包含分类 `id` |
| `POST /subject/category/delete` | `DELETE /subject/category/delete/{id}` | 路径参数 `id` |
| `POST /subject/label/update` | `PUT /subject/label/update` | JSON body，包含标签 `id` |
| `POST /subject/label/delete` | `DELETE /subject/label/delete/{id}` | 路径参数 `id` |

### 明确不纳入范围

- 不修改登录、注册、题目新增、题目分页、文件上传等合法 POST 接口。
- 不改变分类、标签领域服务、DTO 字段、响应体、鉴权语义或业务删除能力。
- 不通过 410 兼容响应保留旧 POST；旧 POST 在路由层不再映射。
- 不修改 `releaseStatus` 或 `finalReleaseStatus` 的未发布状态。

## 任务 1：提交 Backend 契约变更提案

**Owner：** Backend Codex

**文件：**

- 创建：`proposals/backend/2026-08-11-g1-03-formal-http-method-migration.md`
- 参考：`handoff/backend-to-frontend/2026-08-10-gate1-backend-receipt.md`
- 参考：`G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`

- [ ] **步骤 1：** 在提案中记录 4 组旧/正式映射、当前 Controller 注解位置、请求体与路径参数差异、影响范围和回滚边界。
- [ ] **步骤 2：** 在提案中明确旧 POST 不再作为运行时路由，正式端点只保留 2 个 PUT 更新和 2 个 DELETE 删除操作。
- [ ] **步骤 3：** 在提案中写明验证命令：后端 Controller 契约测试、OpenAPI JSON 解析、路径/方法统计和 Frontend API 校验。
- [ ] **步骤 4：** 提交 Backend 提案，并将完整提交哈希交给 PM；未获得 PM 确认前不修改 Java 或后端 API 文件。

## 任务 2：由 Claude Code 后端修改 Backend Controller 和测试

**执行 Owner：** Claude Code 后端

**复验 Owner：** Backend Codex

**文件：**

- 修改：`G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectCategoryController.java`
- 修改：`G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/main/java/com/jackey/subject/app/controller/SubjectLabelController.java`
- 修改：`G:/Dev/backend/Club/CoderClub/coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller/src/test/java/com/jackey/subject/app/controller/SubjectContractTest.java`

- [ ] **步骤 1：** 删除 `SubjectCategoryController` 中旧的 `@PostMapping("/update")` 和 `@PostMapping("/delete")` 方法；保留现有 `@PutMapping("/update")` 和 `@DeleteMapping("/delete/{id}")` 方法及 `@SaCheckLogin`。
- [ ] **步骤 2：** 删除 `SubjectLabelController` 中旧的 `@PostMapping("/update")` 和 `@PostMapping("/delete")` 方法；保留现有 `@PutMapping("/update")` 和 `@DeleteMapping("/delete/{id}")` 方法及 `@SaCheckLogin`。
- [ ] **步骤 3：** 保留正式更新的 JSON body 校验和正式删除的路径参数绑定；不得把删除接口改回 JSON body。
- [ ] **步骤 4：** 保留或补充 MockMvc 成功路径测试：PUT 更新和 DELETE `/delete/{id}` 均能完成请求绑定并返回统一成功响应。
- [ ] **步骤 5：** 补充旧 POST 路由不再映射的测试；测试只断言旧 POST 返回 4xx，不固定 Spring MVC 的具体 404/405 状态。
- [ ] **步骤 6：** 运行：

```powershell
mvn -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am '-Dtest=SubjectContractTest' '-Dsurefire.failIfNoSpecifiedTests=false' test
```

- [ ] **步骤 7：** Claude Code 后端提交 Java 和测试变更；Backend Codex 检查提交差异，回传完整提交哈希、影响文件、验证命令、结果和已知限制。

## 任务 3：由 Claude Code 后端同步 Backend 运行时 OpenAPI 源

**执行 Owner：** Claude Code 后端

**复验/交接 Owner：** Backend Codex

**文件：**

- 修改：`G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json`

执行前置条件：`proposals/backend/2026-08-11-g1-03-formal-http-method-migration.md` 已由 PM 明确确认。Claude Code 后端可以在后端实现提交中同步修改该运行时 API 源，但不得修改交接仓库 `api/` 快照或 `status/sync-manifest.json`。

- [ ] **步骤 1：** 从 `/subject/category/update` 仅保留 PUT 操作。
- [ ] **步骤 2：** 从 `/subject/category/delete/{id}` 仅保留 DELETE 操作，并移除只承载旧 POST 的 `/subject/category/delete` 路径。
- [ ] **步骤 3：** 从 `/subject/label/update` 仅保留 PUT 操作。
- [ ] **步骤 4：** 从 `/subject/label/delete/{id}` 仅保留 DELETE 操作，并移除只承载旧 POST 的 `/subject/label/delete` 路径。
- [ ] **步骤 5：** 保持其他 API 的路径、方法、请求字段、响应字段和鉴权结构不变；预期 OpenAPI 统计从 `45 paths / 47 operations` 变为 `43 paths / 43 operations`。
- [ ] **步骤 6：** 运行：

```powershell
Get-Content -Raw G:/Dev/backend/Club/CoderClub/docs/api/coderclub-openapi.json | ConvertFrom-Json | Out-Null
```

- [ ] **步骤 7：** Claude Code 后端在实现提交中记录批准提案引用和验证结果；Backend Codex 在后端回执中记录源文件新 SHA-256，并说明相对于批准快照的 4 个操作移除和 2 个路径移除。

## 任务 4：由 Claude Code 前端同步契约基线，Frontend Codex 复验消费结果

**执行 Owner：** Claude Code 前端

**复验/回执 Owner：** Frontend Codex

**文件：**

- 修改：`G:/Dev/backend/Club/CoderClubFront/docs/frontend/handoff/api-docs-baseline.json`
- 检查：`G:/Dev/backend/Club/CoderClubFront/src/api/subject.ts`
- 更新：Frontend Codex 角色对应的交接/验收回执和 `status/frontend.json`

- [ ] **步骤 1：** 从前端 API 基线中移除 `POST /subject/category/update`、`POST /subject/category/delete`、`POST /subject/label/update` 和 `POST /subject/label/delete` 记录。
- [ ] **步骤 2：** 保留并校验 4 个正式 PUT/DELETE 记录，其中删除操作使用 `/{id}` 路径参数。
- [ ] **步骤 3：** 检查 `G:/Dev/backend/Club/CoderClubFront/src/api/subject.ts`；当前已使用正式 PUT/DELETE 时不改业务代码，只有基线校验或类型错误要求时才修改对应调用。
- [ ] **步骤 4：** 运行：

```powershell
npm run api:check
npm test
```

- [ ] **步骤 5：** Claude Code 前端提交基线或业务代码变更；Frontend Codex 复验后，在回执中记录 Frontend 提交哈希、使用的契约源/快照哈希、验证结果和是否发生业务代码修改。

## 任务 5：由 PM 更新开发契约快照和同步清单

**Owner：** PM / 跨项目协调 Codex

**文件：**

- 修改：`G:/Dev/backend/Club/coderclub-contract-codex-pm/api/coderclub-openapi.json`
- 修改：`G:/Dev/backend/Club/coderclub-contract-codex-pm/status/sync-manifest.json`
- 修改：`G:/Dev/backend/Club/coderclub-contract-codex-pm/status/pm.json`
- 修改：`G:/Dev/backend/Club/coderclub-contract-codex-pm/pm/reviews/2026-08-10-gate-0-1-pm-acceptance.md`

- [ ] **步骤 1：** 用 Claude Code 后端提交的 OpenAPI 文件生成交接快照；仅对密码和 Token 示例做既定脱敏，不手工保留旧 POST 操作。
- [ ] **步骤 2：** 结构化比较后端源和快照，记录新的源 SHA-256、快照 SHA-256、路径/操作数量和差异摘要。
- [ ] **步骤 3：** 更新 `apiContractCommit`、`backendCommit`、`frontendCommit` 和 `lastSyncedAt`；`finalReleaseStatus` 继续为 `not-published`。
- [ ] **步骤 4：** 验证快照仅保留 4 个正式方法，并确认其他接口没有结构性变化。
- [ ] **步骤 5：** 将 G1-03 从“部分通过”更新为“通过”；只有 Backend、Frontend 和 PM 三方提交哈希及验证结果完整时才关闭。

## G1-03 关闭证据

G1-03 只有在以下证据全部具备后关闭：

- Backend Controller 不再声明 4 个旧 POST 映射。
- Backend MockMvc 测试证明 4 个正式 PUT/DELETE 操作可用，旧 POST 不再成功映射。
- Backend 运行时 API 源和 PM 开发快照均只保留正式方法。
- Frontend API 基线不再包含 4 个旧 POST 记录，`src/api/subject.ts` 使用正式方法。
- Frontend `npm run api:check` 和 `npm test` 通过，并有提交哈希回执。
- PM 同步清单记录更新后的源提交、快照提交和两份 SHA-256。

## 交付约束

- 本次仅写入实施计划，不执行 Backend、Frontend 或 PM 状态文件修改；执行阶段每个角色只能在自己的允许范围内操作。
- Backend Codex 不得直接修改后端项目源代码、测试、交接仓库 `api/` 或 `status/sync-manifest.json`；Claude Code 后端只可在 PM 确认提案后修改后端项目及运行时 API 源。
- Frontend Codex 不得直接修改前端项目；Claude Code 前端不得自行保留旧 POST 调用，也不得修改后端 API。
- 实际代码或项目基线修改任务的 Owner 必须填写 Claude Code 后端或 Claude Code 前端，不得填写 Backend Codex 或 Frontend Codex。
- PM 不修改 Backend/Frontend 业务代码，只负责提案确认、快照更新、状态汇总和验收。
- 本计划完成不会自动改变 `releaseStatus` 或 `finalReleaseStatus`；发布仍需独立完成 Gate 1、M4 和 PM 发布验收。
