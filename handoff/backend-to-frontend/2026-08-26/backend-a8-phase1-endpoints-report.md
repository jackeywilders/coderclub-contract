# 后端实现回执：A8 阶段一 3 门户端点（搜索 / 出题贡献榜 / 用户批量查询）

> **角色：** 后端实现（B-Impl）
> **日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69 已合入 main）
> **决策：** C1-C4 —— `pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`（PR #68）
> **设计规格：** `docs/superpowers/specs/2026-08-26-a8-backend-phase1-endpoints-design.md`（commit `2798baa`，brainstorming 三节获批）
> **实现计划：** `docs/superpowers/plans/2026-08-26-a8-backend-phase1-endpoints-plan.md`（commit `d62c7e7`）

## 1. 来源与提交

| 项 | 值 |
| --- | --- |
| 来源分支（后端项目） | `feat/backend-a8-phase1-portal-endpoints`（基于 main @ 之后） |
| 实施提交（5 个，自底向上） | `bb9ec40`（search）、`70b146b`（搜索修复轮）、`9192e3d`（contribute + Feign 消费者）、`fdbcb53`（auth list-by-identifiers）、`c4e1efb`（源文档登记） |
| 分支 tip | `c4e1efb`（完整 `c4e1efb9e28a1883ac527ab219fe77d152bcc6df`） |
| PR | **#12**（https://github.com/jackeywilders/coderclub/pull/12，base main） |
| 回执提交 | 见本目录 `*-summary.json`（提交后补） |

## 2. 实施明细（3 端点）

### 2.1 `POST /subject/getSubjectPageBySearch`（subject）

- 请求 `SubjectSearchQueryDTO`（extends PageInfo）：`keyWord`（`@NotNull(groups=Query)` + `@Size(max=50)`）+ `subjectType`/`subjectDifficult`/`categoryId`/`labelId` 可选
- **C4 空串语义**：keyWord 缺失 → 400；空串/纯空白 → DomainService 早退空页（total=0，不触达 SQL，Controller 加同款守卫保测试契约）
- 匹配：`subject_name LIKE CONCAT('%',#{keyWord},'%')` 单列 + `is_deleted=0` + left join `subject_mapping`（categoryId/labelId）；`count(distinct a.id)` 防映射多行膨胀
- 响应 `ResponseResult<PageResult<SubjectSearchItemVO>>`（id/subjectName/subjectType/subjectDifficult/categoryId/labelId/labelName/optionList）
- `SubjectSearchItemVO` 带 `@AutoMapper(target=SubjectInfoBO.class)`（修复轮 70b146b：消真实运行时 ConvertException→500）

### 2.2 `POST /subject/getContributeList`（subject）

- 请求 `ContributeListQueryDTO{topN}`（可选；缺省 10、>20 截断 20、<1 回退 10；body 可省略 `@RequestBody(required=false)`）
- **C3 分组**：`GROUP BY created_by`（不用 settle_name）+ `COUNT(*)` 降序 + `is_deleted=0` + `limit #{topN}`
- 响应 `ResponseResult<List<ContributeItemVO>>`：`{userName, nickName, count}`；空 → `[]`
- **C2 nickName**：Controller 层经 Feign `AuthUserFeignClient.listByUserNames`（`POST /auth/user/list-by-identifiers`，携带 Sa-Token）批量取号组装；Feign 失败/缺失 → 降级 userName（200 不 500）
- `ContributeAggBO` 置于 infra/basic/entity（domain→infra 单向依赖约束，避免循环依赖；契约形状不变）

### 2.3 `POST /auth/user/list-by-identifiers`（auth，C2 方案②）

- 请求 `UserIdentifierQueryDTO{identifiers:List<String>, type}`：identifiers 必填 + `@Size(max=100)`（>100 → 400）；空数组/过滤后空/无匹配 → `[]`（不 400）
- 匹配：`auth_user.user_name IN (...)` + `is_deleted=0`（QueryWrapper.in + eq）
- 响应 `ResponseResult<List<IdentifierUserItemVO>>`：`{userName, nickName, avatar}`
- 语义：仅内部跨服务查询，不作 C 端对外宣传（契约登记完整）
- 校验组说明：auth 模块无 Groups 类（full 仓库仅 subject-common 有），按 auth 既有 DTO 惯例用默认校验组 + `@Validated`（行为等价：缺 identifiers→400；简报已授权"以 auth 实际为准"）

## 3. 测试证据

- **全量** `mvn test`（项目根）→ exit 0（BUILD SUCCESS）
- **SubjectContractTest** → **57/57**（52 基线 + 3 search + 2 contribute；命令 `-pl coder-club-subject-app-controller -am -Dtest=SubjectContractTest -DfailIfNoTests=false -Dsurefire.failIfNoSpecifiedTests=false`）
- **AuthContractTest** → **10/10**（8 基线 + 2 新用例；`-pl coder-club-auth-app-controller -am -Dtest=AuthContractTest -DfailIfNoTests=false -Dsurefire.failIfNoSpecifiedTests=false`）
- 新用例覆盖：search（空串空页不 400/缺 keyWord 400/命中组装）、contribute（空库 `[]`/topN + Feign nickName 组装）、auth list（无匹配 `[]`/缺 identifiers 400）
- 每任务经独立子代理实现 + 任务审查：Task1 修复 1 轮（F-1 Critical VO@AutoMapper、F-2 Important distinct 全解；F-3 裁定保留 stub 同 A2 模式）；Task2/3/4 review clean（无 Critical/Important；Minor 已 defer 账本）

## 4. 源文档登记与契约 SHA

后端运行时契约源 `docs/api/coderclub-openapi.json`（本实现更新）：
- **LF 归一化 SHA-256：BEFORE `A8C6A4607EA21FBFE932D7CDB6464CF77595846F133A0DC42AD8C56291A6DD26` → AFTER `BA74B152730A2F532A8118C18F20AB395CCD4AEA04DB672A17120833705493B1`**
- 语义差异：+3 路径（search/contribute/auth list-by-identifiers）+ 9 schema（6 业务 + 3 包装）；无字段级破坏
- 契约快照：`contractSnapshotSha256 = 8ebcda53`（任务书指定当前值；PM 验收后全链同步 +3 语义差异）

## 5. 已知限制 / 待云端验证

1. groupBy SQL / search SQL 真实执行（单测为 Controller 契约级，Mapper mock 于 DomainService 外）——云端真实请求验证补充
2. subject Feign 跨服务联调（auth 端点本体与本端点已在同一分支实现，待合入后真实联调复核字段反序列化）
3. 401 端到端（standalone MockMvc 推断 + GlobalExceptionHandler @ResponseStatus(UNAUTHORIZED) 佐证）
4. topN 归一边界、auth @Size(100) 边界无专属单测（简报仅要求 2 Controller 用例；云端验证补充）

## 6. 声明

- 未修改交接仓库 `api/` 快照与 `status/sync-manifest.json`（PM 验收后全链同步）
- 未修改其他端点/鉴权/错误码/表结构；未新增索引；未跨 `option_content`/`subject_answer` 子表搜索
- 本回执不含真实环境信息（规则 8 脱敏）

## 7. 后端评审复核签署（待）

- [ ] 代码级复核（3 端点 + C4/C3/C2 语义 + 分层）— 待
- [ ] 独立测试复验（57/10 + 全量）— 待
- [ ] 源文档 SHA 核对（A8C6A460→BA74B152）+ 3 端点契约完整 — 待
- [ ] 签署本回执 — 待

**复核签署**：后端评审（B-Review），2026-08-26（工作底稿：待补）