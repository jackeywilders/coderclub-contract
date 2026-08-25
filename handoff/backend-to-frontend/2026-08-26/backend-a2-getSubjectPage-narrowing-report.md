# 后端实现回执：A2 getSubjectPage 请求体运行时收窄（PR #49 任务书）

> **角色：** 后端实现（B-Impl）
> **日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/getSubjectPage-runtime-narrowing-implementation-task.md`（PR #49 已合入 main）
> **决策依据：** 案 B/C（运行时收窄对齐契约）—— `pm/reviews/2026-08-26/getSubjectPage-schema-alignment-decision.md`（PR #41）

## 1. 来源与提交

| 项 | 值 |
| --- | --- |
| 来源分支（后端项目） | `feat/backend-a2-getSubjectPage-narrow`（基于 main @ 88f7336） |
| 实施提交 | `6b2aedd`（完整 `6b2aeddbb775f5039fa50a3feaa779f05e6fe0ed`） |
| PR | **#8**（https://github.com/jackeywilders/coderclub/pull/8，base main） |
| 回执提交 | 见本目录 `*-summary.json`（提交后补） |

## 2. 实施内容

1. **controller 收窄**：`SubjectController.page`（`/subject/getSubjectPage`）请求体 `SubjectInfoDTO`（宽入 14 字段）→ **`SubjectPageQueryDTO`**（6 字段全生效）；保留 `@Validated(Groups.PageQuery)` 分组（空标记接口，行为不变）。
2. **新建 DTO**：`SubjectPageQueryDTO`（`app/entity/`，extends `PageInfo` + 4 筛选字段），`@AutoMapper(target=SubjectInfoBO.class)` 显式映射 6 字段（pageNo/pageSize/subjectDifficult/categoryId/labelId/subjectType）→ BO；service 层接口与 Domain 链路**不变**（仍收 `SubjectInfoBO`）。
3. **行为保持（硬条件）**：多余字段（`subjectName`/`settleName`/`subjectScore`/`subjectParse`/`subjectAnswer` 等）由 Jackson 静默忽略（`FAIL_ON_UNKNOWN_PROPERTIES` 默认 false），**不 400**——新增用例显式验证。
4. **源文档**：`docs/api/coderclub-openapi.json` `SubjectPageQueryDTO` description：「分页查询请求体。实际绑定 SubjectInfoDTO，此处仅展示常用过滤字段。」→「getSubjectPage 请求体即本 DTO，6 字段全部参与筛选。」（A2 决策附带条件 2，已批准，无需另行提案）

## 3. 测试命令与结果

- **全量回归**：`mvn test`（项目根）→ **BUILD SUCCESS**（exit 0，全部模块）
- **SubjectContractTest**：`mvn test -pl coder-club-subject/coder-club-subject-app/coder-club-subject-app-controller -am -Dtest=SubjectContractTest -DfailIfNoTests=false -Dsurefire.failIfNoSpecifiedTests=false` → **Tests run: 52, Failures: 0, Errors: 0**（51 基线 + 1 新增）
- **新增用例** `getSubjectPage_shouldIgnoreExtraFields_andNotReturn400`：
  - 请求体 = 6 契约字段 + 5 个多余字段（subjectName/settleName/subjectScore/subjectParse/subjectAnswer）→ **HTTP 200**（非 400）
  - 真实 `@AutoMapper`（SubjectPageQueryDTO→SubjectInfoBO，纯 JUnit 可构造）验证：BO 的 pageNo=1/pageSize=10/subjectDifficult=1/categoryId=2/labelId=3/subjectType=1 全量透传；subjectName/settleName/subjectScore 为 null

## 4. 真实请求验证（§2.6）——已执行 ✅

云端中间件环境验证（auth 3100 + subject 3000 直连 Nacos/MySQL，Nacos 凭据走用户级环境变量）。测试账号：admin（脱敏，凭据不落盘）。

| 组 | 请求要点 | 响应 | 结论 |
| --- | --- | --- | --- |
| 无登录态 | `POST /subject/getSubjectPage` `{}` | **HTTP 401** | `@SaCheckLogin` 生效 ✅ |
| A（6 契约字段） | `{"pageNo":1,"pageSize":5,"subjectDifficult":1,"subjectType":1}` | **HTTP 200**，`total=6`、`listCount=5`、首个条目 `subjectType=1, subjectDifficult=1` | **6 字段全部参与筛选** ✅（对照无筛选 `total=28`） |
| B（6 字段 + 多余字段） | A + `subjectName/settleName/subjectScore/subjectParse/subjectAnswer/categoryIds/labelIds` | **HTTP 200（未 400）**，`total=6`、`listCount=5`、首个条目与 A 组一致（id=328） | **多余字段静默忽略、不 400** ✅（硬条件满足） |

- **登录链**：`POST /auth/login` 返回 token（tokenName=Authorization）→ 携带 `Authorization` 头调用 getSubjectPage
- **筛选证据**：无筛选 total=28 vs `subjectType=1+subjectDifficult=1` total=6——筛选参数确实压缩结果集
- **多余字段证据**：B 组与 A 组结果逐位一致（total=6、id=328 相同）——多余字段未参与查询
- 补充：真实验证于 2026-08-26 补做（本回执初版因本地无运行环境标记为待验证，见 §6 已知限制变更）

## 5. 契约 SHA-256 与语义差异

后端运行时契约源 `docs/api/coderclub-openapi.json`（本实现更新 description）：

| 阶段 | SHA-256（前 8 位） | 语义差异 |
| --- | --- | --- |
| 修改前 | `05933BEA` | —（= 已同步快照源 SHA，前端基线 `0DAE8D3A` 不漂移） |
| 修改后 | `A8C6A460` | `SubjectPageQueryDTO.description` 文案更新（「即本 DTO，6 字段全部参与筛选」）；**无字段/结构/路径/方法变更** |

## 6. 已知限制

1. ~~真实请求验证待运行环境~~ **已解除**：2026-08-26 云端中间件环境完成真实请求验证（见 §4），mock 层 + 真实层双验证齐备
2. 契约快照（`api/coderclub-openapi.json`、`0DAE8D3A`）零变更；`sync-manifest` 由 PM 在验收后全链同步

## 7. 声明

- 未修改交接仓库 `api/` 快照与 `status/sync-manifest.json`
- 未修改其他端点/鉴权/错误码/路径；未新增契约字段（前端 `keyword` 死参数不在本期范围，A3 已处理）
- 本回执不含真实环境信息（规则 8 脱敏）

## 8. 后端评审复核签署（待）

- [ ] 代码级复核（controller 收窄 + DTO 显式映射 + 行为保持）— 待
- [ ] 独立复验（52/52 回归 + 新增用例）— 待
- [ ] 源文档 description 更新 + SHA 核对 — 待
- [ ] 签署本回执 — 待

**复核签署**：后端评审（B-Review），2026-08-26（工作底稿：待补）