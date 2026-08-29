# 任务书：A8 阶段一后端实现（3 端点：搜索 / 出题贡献榜 / 用户批量查询）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-26
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **提案：** `proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（PR #67）
> **决策：** `pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68，C1-C4 已决，C2 选方案②放宽为 3 端点）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md` § 4.3/4.5/6

## 1. 目标

实现 A8 阶段一门户化的 3 个新契约端点，并在后端源文档 `docs/api/coderclub-openapi.json` 登记契约定义（已批准，可作实现一部分更新源文档；交接仓库 `api/` 快照与 `sync-manifest` 由 PM 验收后全链同步，**你不得修改**）。

## 2. 实施边界（仅以下 3 端点，禁止扩大）

### 2.1 `POST /subject/getSubjectPageBySearch`（subject 模块）

- 请求体 `SubjectSearchQueryDTO`（extends PageInfo）：`keyWord`（必填 string ≤50）、`subjectType`/`subjectDifficult`/`categoryId`/`labelId`（可选，与 `SubjectPageQueryDTO` 对齐）
- **keyWord 校验（按决策 C4，注意与提案文字差异）**：缺失 `keyWord`（null）→ 400；**空串 `""` → 返回空列表（total=0，不 400）**——实现用 `@NotNull(groups=Query)` 而非 `@NotBlank`（后者会把空串也判 400，违背 C4）；service 层对空串提前返回空页
- 匹配：`subject_name LIKE CONCAT('%', #{keyWord}, '%')` 单列（`subject_name` 即题干本体，决策 C1）；`is_deleted=0`
- 响应：与 `getSubjectPage` 同构 `ResponseResult<PageResult<SubjectSearchItemVO>>`——`PageResult`（pageNo/pageSize/total/totalPages/list）；列表项 `id`/`subjectName`/`subjectType`/`subjectDifficult`/`categoryId`/`labelId`/`labelName`/`optionList`
- 鉴权：`@SaCheckLogin`（无登录 401）；错误码沿用现有体系，不新增

### 2.2 `POST /subject/getContributeList`（subject 模块）

- 请求体 `ContributeListQueryDTO`：`topN`（可选 integer，默认 10，上限 20，超出按 20 截断）；可不传 body
- 分组语义（决策 C3）：`subject_info.created_by` 分组，`COUNT(*)` 降序 TOP N，`is_deleted=0`；**不用 `settle_name`**
- 响应：`ResponseResult<List<ContributeItemVO>>`：`list[{ userName, nickName, count }]`；无题目 → 空列表 `[]`（非 null）
- `nickName` 来源（决策 C2）：subject 经 Feign 调 §2.3 批量查询端点按 `created_by` 集合取号
- 鉴权：`@SaCheckLogin`

### 2.3 `POST /auth/user/list-by-identifiers`（auth 模块，C2 方案②）

- 请求体：`UserIdentifierQueryDTO`：`identifiers`（必填，string 数组，长度上限 100）、`type`（可选：`userName`，预留扩展）
- 匹配：`auth_user.user_name IN (identifiers)` 且 `is_deleted=0`
- 响应：`ResponseResult<List<IdentifierUserItemVO>>`：`list[{ userName, nickName, avatar? }]`（展示口径遵循 `UserInfoVO` userName/nickName；本次消费方为 subject 贡献榜，`avatar` 可选不带）
- 空输入/无匹配 → 空列表；鉴权：`@SaCheckLogin`（subject Feign 调用时携带 Sa-Token 上下文）
- 语义约束：本端点仅作内部跨服务查询，**不作为 C 端业务端点对外宣传**（契约登记仍完整定义）

## 3. 禁止事项

- 不修改/删除任何现有端点、字段、鉴权、错误码语义；不动 `api/` 快照与 `status/sync-manifest.json`（PM 验收后全链同步）
- 不新增索引/不动表结构（云端库与 schema 已核验一致，`subject_name` LIKE 量级小，不建索引）
- 不扩大匹配范围（不跨 `option_content`/`subject_answer` 子表搜索）
- 边界检查：字符集注意（云端 practice/interview 老表 utf8mb3 系，本任务不触达；subject/auth 表为 utf8mb4，正常）

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送后端仓库（Conventional Commits，如 `feat(subject): add getSubjectPageBySearch and getContributeList for portal (A8 phase-1)`、`feat(auth): add user list-by-identifiers endpoint (A8 phase-1)`），建议单 PR 覆盖 3 端点。
2. 后端源文档 `docs/api/coderclub-openapi.json` 同步新增 3 端点定义（已批准），LF 字节态 SHA 变更记录在回执（before/after）。
3. 回执双轨落 `handoff/backend-to-frontend/2026-08-26/`：Markdown（来源与提交哈希、3 端点实现明细、测试证据、源文档 diff）+ `*-summary.json`（模板字段；`taskId=A8-P1-BE`、`contractSnapshotSha256=8ebcda53`（当前值，验收后 PM 更新）、`verificationResult`）。
4. 完成通知带四字段（实施 SHA、回执 SHA、PR 号、R2 状态）告知 B-Review 复核签署，签署后转 PM 验收。

## 5. 验收标准

- [ ] 3 端点按 §2 语义实现（含 C4 空串空列表、C3 created_by 分组、C2 nickName 批量查询链路）
- [ ] `SubjectContractTest` 52/52 回归不回归 + 新端点用例：search（命中/空串空列表/缺字段 400/筛选组合）、contribute（空库空列表/topN 截断/排序）、auth list-by-identifiers（空列表/批量/无匹配）
- [ ] 源文档 3 端点定义登记完整（请求/响应/鉴权/错误码/示例），LF SHA before/after 记录
- [ ] 未改 `api/` 快照与 `sync-manifest`；未动其他端点
- [ ] 回执双轨 + 四字段远端证据

## 6. 关联

- 提案：`proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（PR #67）
- 决策：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68）
- 后续：PM 验收 → 快照全链同步（+3 语义差异）→ 前端门户化任务书（F-Impl）