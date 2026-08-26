# PM 决策：A8 阶段一门户化契约提案确认（2+1 端点，C1-C4）

> 角色：协调 PM
> 决策日期：2026-08-26
> 提案：`proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（B-Review，PR #67 已合入 main）
> 状态：**确认通过（C2 选方案②，放宽为 3 端点）；转 B-Impl 实现任务书**

## 1. 确认内容

| 端点 | 确认语义 |
| --- | --- |
| `POST /subject/getSubjectPageBySearch` | `SubjectSearchQueryDTO`（keyWord ≤50 必填 + 可选筛选四字段）；`subject_name` 单列 LIKE；响应与 `getSubjectPage` 同构（`PageResult<SubjectSearchItemVO>`，含 optionList 供前端复用）；`@SaCheckLogin` |
| `POST /subject/getContributeList` | `ContributeListQueryDTO`（topN 默认 10 上限 20）；`created_by` 分组 + `auth_user` 关联；`ResponseResult<List<ContributeItemVO>>`（userName/nickName/count）；`@SaCheckLogin` |
| `POST /auth/user/list-by-identifiers`（**新增，C2 方案②**） | auth 侧按 identifiers（userName/openid）批量查询用户（userName/nickName）；供 subject 贡献榜及其后域（阶段三评论、阶段四历史）复用 |

## 2. C1-C4 决策

| # | 项 | 决策 |
| --- | --- | --- |
| C1 | 搜索匹配字段 | **确认 `subject_name` 单列 LIKE**——后端无独立题干列，`subject_name` 即题干本体（语义等价设计文档 §4.5「题干」，前端搜索页展示同一字段）；不跨子表匹配 |
| C2 | 贡献榜 nickName 来源 | **选方案②**：新增 `POST /auth/user/list-by-identifiers`（放宽任务书「仅新增 2 端点」约束）。理由：openid 形态 userName 展示性差，右栏贡献榜需可读昵称；该查询能力为后续域（阶段三社区评论/动态作者、阶段四面试历史、点赞列表）的公共需求，一次补齐避免逐域补；subject 侧经 Feign 消费，封装为 DomainService 内查询，不暴露跨服务细节 |
| C3 | 分组键 | **知悉**：`created_by` 分组（不用 `settle_name`，非用户标识）——云端核验支撑：实际 `created_by` = `admin`/`user` 等与 `auth_user.user_name` 关联成立 |
| C4 | keyWord 空串语义 | **确认**：缺失字段 → 400；空串 → 空列表（total=0，不 400） |

## 3. 云端数据库结构核验（2026-08-26 用户提供实时 dump，本地对比）

- **表/列级一致性**：云端 25 表 = schema 文档（`docs/database/schema/doc_jc-club-init.sql`）25 表，表集合无差异、逐表列集合无差异——schema 文档为云端实际结构的准确镜像（含 A1 `subject_category.sort` 已落库）。
- **关联键成立**：`subject_info.created_by` ↔ `auth_user.user_name`（云端实际值验证）。
- **字符集风险提示**（阶段二~四实施前评估）：`interview_history`/`interview_question_history` 为 latin1/utf8mb3，`practice_*`/`subject_liked` 为 utf8mb4_bin 系——老表非 utf8mb4，中文内容与后续域写入存在乱码/兼容风险；阶段四（interview 域）前建议评估表字符集迁移（utf8mb4），阶段二（practice）写入前确认会话字符集行为。字符集变更属 DB DDL 类，届时按 A1 模式由用户/运维执行并另行决策。
- 云端 dump 含真实环境信息，核验结论落仓库不附真实值（规则 8；真实值仅存在于用户本地）。

## 4. 后续链

1. B-Impl 实现任务书（3 端点：search + contribute + auth list-by-identifiers；含契约源文档 `docs/api/coderclub-openapi.json` 同步——B-Review proposal §2 已给实现参考）
2. B-Impl 回执 → B-Review 复核签署 → PM 验收 → 快照全链同步（P1/P3 模式，语义差异 +3）
3. 前端门户化任务书（F-Impl，含 userinfo 字段对齐并入——openFinding `userinfo-fields-mismatch`）

## 5. 关联

- 任务书：`pm/requirements/2026-08-26/portal-phase1-backend-contract-proposal-task.md`（PR #66）
- 提案：`proposals/backend/2026-08-26/portal-phase1-search-contribute-proposal.md`（PR #67）
- 设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）

决策：协调 PM，2026-08-26