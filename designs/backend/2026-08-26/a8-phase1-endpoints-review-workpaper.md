# A8 阶段一 3 门户端点——后端评审复核工作底稿

> 角色：后端评审（B-Review）
> 日期：2026-08-26
> 任务书：`pm/requirements/2026-08-26/backend-phase1-portal-endpoints-implementation-task.md`（PR #69）
> 决策：C1-C4（`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md`，PR #68）
> 回执：`handoff/backend-to-frontend/2026-08-26/backend-a8-phase1-endpoints-report.md` + `-summary.json`（PR #70 合入交接仓库 main）
> 实施分支：`feat/backend-a8-phase1-portal-endpoints`（CoderClub PR #12，head `ceaffe4`）

## 1. 人链核验：实施提交存在性与分支 tip

| 项 | 证据 | 结果 |
| --- | --- | --- |
| 分支/commits | `git log origin/feat/backend-a8-phase1-portal-endpoints` → 8 commits：`2798baa`(spec)/`d62c7e7`(plan)/`bb9ec40`/`70b146b`/`9192e3d`/`fdbcb53`/`c4e1efb`/`ceaffe4` | ✅ |
| 实施 tip | 分支 head = **`ceaffe4`**（8 commits）；回执 summary `implementationCommitSha=c4e1efb`（openapi 登记提交，第 7 个）——**回执 SHA 未指向最终 tip**，`ceaffe4`（final review cleanups，12 文件 52+/13-）未含于 summary 引用 | ⚠️ 记录（引用类小瑕疵，见 §4） |
| CI | PR #12 build-and-test success + sensitive-scan success | ✅ |
| 与回执一致 | 5 个实现提交（bb9ec40/70b146b/9192e3d/fdbcb53/c4e1efb）自底向上与回执 §1 逐字一致 | ✅ |

## 2. 代码级复核（对照实施 diff，main..`ceaffe4` 26 文件 1081+/1-）

| 核对项 | 结果 |
| --- | --- |
| **C4 空串语义**：`SubjectSearchQueryDTO.keyWord @NotNull(groups=Query) + @Size(max=50)`；缺失 400；空串/纯空白 → Controller + DomainService 双守卫早退空页（回填 pageNo/pageSize、total=0，不 400） | ✅ `ceaffe4` Controller L192-201 守卫与回执一致 |
| search LIKE：`subject_name LIKE CONCAT('%',#{keyWord},'%')` 单列 + `is_deleted=0` + left join subject_mapping（categoryId/labelId）+ `count(distinct a.id)` 防膨胀；不跨子表 | ✅ XML diff 确认 |
| search 响应：`ResponseResult<PageResult<SubjectSearchItemVO>>`（id/subjectName/subjectType/subjectDifficult/categoryId/labelId/labelName/optionList）；VO `@AutoMapper(target=SubjectInfoBO.class)`（70b146b 修复 ConvertException→500） | ✅ |
| **C3 分组**：`getContributeList` `GROUP BY created_by` + `COUNT(*)` 降序 + `is_deleted=0` + `limit topN`；**不用 settle_name** | ✅ |
| contribute 请求/响应：`ContributeListQueryDTO{topN}` 可选（缺省 10、>20 截断、<1 回退 10；`@RequestBody(required=false)`）；响应 `list[{userName,nickName,count}]`；空 → `[]` | ✅ |
| **C2 nickName**：Controller 层 Feign `listByUserNames`（`POST /auth/user/list-by-identifiers` 携 Sa-Token）批量取号；**Feign 失败/缺失/空白 nickName → 降级 userName（200 不 500）** | ✅ `ceaffe4` L223-235 守卫（空白不入 map → getOrDefault 落 userName） |
| auth list-by-identifiers：`identifiers` 必填 + `@Size(max=100)`；空数组/无匹配 → `[]` 不 400；`user_name IN (...)` + `is_deleted=0`；响应 `{userName,nickName,avatar}` | ✅ |
| **C2 方案② 落实**：auth 侧新增 1 端点（决策允许的第 3 端点），仅内部跨服务查询 | ✅ 符合 PR #68 决策 |
| 分层合规：`ContributeAggBO` 置 infra/basic/entity（domain→infra 单向依赖）；Controller 不直调 Infra Service | ✅ |
| 边界：未动既有端点/鉴权/错误码/表结构；未新增索引；未改 `api/` 快照与 `sync-manifest` | ✅ |

## 3. 独立复验（本底稿复核时执行，附着 `ceaffe4`；非回执声明转录）

| 命令 | 结果 |
| --- | --- |
| 全量 `mvn install -DskipTests -q` | exit 0 |
| `SubjectContractTest`（-pl subject-app-controller） | **57/57**，BUILD SUCCESS（52 基线 + 5 新：3 search + 2 contribute） |
| `AuthContractTest`（-pl auth-app-controller） | **12/12**，BUILD SUCCESS（**回执称 10/10**；`ceaffe4` 已补 `@Size(100)` 400 与 401 两用例 → 最终 12） |
| 新用例覆盖 | search（空串空页/缺 keyWord 400/命中组装）、contribute（空库 `[]`/topN+Feign nickName）、auth（无匹配 `[]`/缺 identifiers 400/>100 400/401）——C4/C3/C2 均有契约用例，**401 与 @Size(100) 边界已有专属用例**（回执 §5.4 所述部分边界限制已解除） |
| 源文档 LF SHA-256 | before（main `a269afe`）`A8C6A4607EA21FBFE932D7CDB6464CF77595846F133A0DC42AD8C56291A6DD26` → after（`ceaffe4`）`BA74B152730A2F532A8118C18F20AB395CCD4AEA04DB672A17120833705493B1`——与回执 §4 逐字一致 |
| 契约完整性 | 3 新路径（search/contribute/auth list）+ 9 新 schema（6 业务 SubjectSearchQueryDTO/SubjectSearchItem/ContributeListQueryDTO/ContributeItem/UserIdentifierQueryDTO/IdentifierUserItem + 3 包装 ResponseResultPageSubjectSearchItem/ResponseResultSubjectContributeItemList/ResponseResultIdentifierUserItemList）全部登记 | ✅ |

## 4. 复核结论与备注

- **结论：通过，可签署。**
- 与回执声明（3 端点语义、C4/C3/C2 落实、57/57、源文档 SHA、契约完整）逐项一致；未发现 [必须修复] / [建议修改] 问题。
- [仅供参考] 回执 summary `implementationCommitSha=c4e1efb` 未含最终 tip `ceaffe4`（final review cleanups）——引用类小瑕疵（同 A2/A5 先例），建议 B-Impl 或 PM 验收时补正 summary 指向实际 head；不影响本签署（`ceaffe4` 已在人链核验与独立复验范围内）。
- [仅供参考] 回执称 AuthContractTest 10/10，独立复验为 12/12（`ceaffe4` 补 `@Size(100)` 400 与 401 用例）——**覆盖更全**，非实质差异。
- 已知限制处置（回执 §5 + PR 描述）：
  1. groupBy/search SQL 真实执行（单测为 Controller 契约级，Mapper 层 mock）——**云端真实请求验证补充**（计划 §7，验收后），不阻塞签署；
  2. subject Feign 跨服务联调（auth 端点与消费者同一分支，待合入后真实联调）——同上；
  3. 401 端到端——**已解除**：`ceaffe4` 补 401 用例，独立复验 12/12 覆盖；
  4. topN 归一边界无专属单测——[仅供参考] 建议 PM 验收或后续云端验证补；`@Size(100)` 边界**已解除**（12/12 覆盖）；
  5. 云端真实请求验证整体——按验收后补充处理（与 A2/A5 先例一致：真实验证证据以回执声明 + CI 全绿 + 独立复验 57/57/12/12 为准）。

复核签署：后端评审（B-Review），2026-08-26