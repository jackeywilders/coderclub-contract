# Proposal：A8 阶段一门户化新增 2 端点（批量提案）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-26
> **任务书：** `pm/requirements/2026-08-26/portal-phase1-backend-contract-proposal-task.md`（PR #66，提交 `92c6ef1d`）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）§ 4.3/4.5/6
> **类型：** 批量契约提案（2 端点单文件）
> **状态：** 待 PM 确认

## 1. 现状事实（2026-08-26 后端勘察）

| 项 | 事实 |
| --- | --- |
| 现有搜索能力 | 无按关键词搜索题目的端点；`getSubjectPage` 请求体 6 字段无 `keyWord`（A2 已收窄）；`subjectName` 为非筛选死参数 |
| 题干字段 | `subject_info.subject_name`（varchar 128，comment「题目名称」）即题干本体——**无独立题干列**；对应契约 `SubjectInfoDTO.subjectName` |
| 创作者标识 | `subject_info.created_by`（varchar 32）存创建人；运行时由 `save()` 经 Feign `getUserInfo(token)` 取 `userInfo.userName` 写入（`SubjectController.save` L71） |
| 用户字段口径 | 契约 `UserInfoVO`：`userName`/`nickName`；`auth_user.user_name`/`nick_name` 为 DB 列 |
| 样例关联性 | `doc_jc-club-init.sql`：`subject_info.created_by` = `<sample-openid-NN>`（openid 形态占位）；`auth_user.user_name` 同为 openid 形态（A5 脱敏后 `test-user-NN`）——**关联键 = created_by ↔ auth_user.user_name**；`settle_name` 样例为 NULL（自由文本"出题人名"，非用户标识，不与 auth_user 关联） |
| 跨服务能力 | subject → auth 现有 Feign 仅 `GET /auth/user/info`（按 token 查当前用户）；**无按 openid/userName 批量查询端点** |

## 2. 端点提案

### 2.1 `POST /subject/getSubjectPageBySearch`（搜索）

| 项 | 定义 |
| --- | --- |
| 路径/方法 | `/subject/getSubjectPageBySearch` POST |
| 鉴权 | 沿用 `getSubjectPage` 现状：`@SaCheckLogin`（无登录态 401）——与设计文档一致，无差异 |
| 请求体 | `SubjectSearchQueryDTO`（新 DTO，extends PageInfo）：`keyWord`（必填 string ≤50）、`subjectType`/`subjectDifficult`/`categoryId`/`labelId`（可选，与 `SubjectPageQueryDTO` 对齐） |
| keyWord 边界 | 缺失 `keyWord` 字段 → HTTP 400（`@NotBlank(groups=Query)`）；空字符串 `keyWord=""` → **返回空列表（total=0，不抛 400）**——避免空关键词语义非法 |
| 匹配范围 | `subject_name LIKE '%keyWord%'`（单列；因后端无独立题干列，`subject_name` 即题干本体） |
| 不做 | 不扩全文检索/拼音/分词；不跨子表 `option_content`/`subject_answer` 匹配（避免超范围 + 性能） |
| 响应 | 与 `getSubjectPage` 同构：`ResponseResult<PageResult<SubjectSearchItemVO>>`——`PageResult`（pageNo/pageSize/total/totalPages/list）+ 列表项含 `id`/`subjectName`/`subjectType`/`subjectDifficult`/`categoryId`/`labelId`/`labelName`/`optionList`（前端列表可复用） |
| 错误码 | 沿用现有体系（401 未登录 / 400 校验失败）；不新增错误码 |
| DDL 影响 | 无（不动表结构；`subject_name` 已有，LIKE 查询走 MySQL 默认索引行为，不建新索引——量级小） |

**建议实现参考（供 B-Impl 任务书引用）**：`SubjectInfoMapper` 新增 `queryBySearch`（XML 动态条件 `AND subject_name LIKE CONCAT('%', #{keyWord}, '%')` + 复用既有筛选维度 + `is_deleted=0`），DomainService 新增 `pageBySearch(SubjectSearchBO)`；`SubjectController` 新增 `search` 方法 `@SaCheckLogin`。

### 2.2 `POST /subject/getContributeList`（出题贡献榜）

| 项 | 定义 |
| --- | --- |
| 路径/方法 | `/subject/getContributeList` POST |
| 鉴权 | 沿用登录鉴权：`@SaCheckLogin`（无登录态 401） |
| 请求体 | `ContributeListQueryDTO`：`topN`（可选 integer，默认 10，上限 20，超出按 20 截断）；亦可不传 body |
| 分组语义 | `subject_info.created_by` 分组（关联键 = `auth_user.user_name`），`COUNT(*)` 降序取 TOP N，`is_deleted=0` |
| 响应 | `ResponseResult<List<ContributeItemVO>>`：`list[{ userName, nickName, count }]`（count 为该出题人题目数量） |
| 空数据 | 无题目 → 空列表（`[]`，非 null） |
| 不做 | 不新增权限/错误码；不动其他端点 |
| DDL 影响 | 无 |

**昵称来源方案（待 PM 决策，见 §3 C2）**：本端点响应 `nickName` 需 auth_user 关联；因现有契约无按标识批量查询端点，且任务书约束「仅新增 2 端点」，实现阶段默认方案为 **B-Impl 内部按 `created_by` 集合逐个/小批量 Feign 调 `GET /auth/user/info` 不可行**（该端点按登录 token 取当前用户，非按 openid）——**需 PM 在 B-Impl 任务书前拍板下列之一**（本提案推荐 方案 ②）：

- **方案 ①（响应含 userName+count，不含 nickName）**：改动最小、最符合「仅新增 2 端点」；前端右栏显示 `userName`（openid 形态展示性差）——**不推荐**。
- **方案 ②（响应含 userName+nickName+count，auth 侧补按 openid/userName 批量查询能力）**：更符合 `UserInfoVO` 口径；但`/auth` 侧需 B-Impl 新增 1 个查询端点（如 `POST /auth/user/list-by-identifiers`）→ **超出本任务「仅新增 2 端点」字面约束，需 PM 明确批准放宽**。
- **方案 ③（响应仅 nickName+count，created_by 内部解析）**：subject 侧无 nickName 数据源，仍需 auth 能力——同 ② 依赖，实现复杂，不推荐。

## 3. 与设计文档的冲突/待决点（明示交 PM 决策）

| # | 冲突点 | 设计文档/任务书表述 | 后端现状 | 建议 |
| --- | --- | --- | --- | --- |
| **C1** | 搜索匹配字段 | §4.5「keyWord 匹配 subjectName + 题干关键词 LIKE」 | **无独立题干列**，`subject_name` 即题干本体 | 落地为 **`subject_name` 单列 LIKE**（语义等价"题干"）；不跨子表，避免超范围。需 PM 确认口径 |
| **C2** | 贡献榜 nickName 来源 | 任务书 §2.2「展示字段遵循契约 UserInfoVO 侧 userName/nickName 口径」 | subject 服务无 auth_user 数据；现有 Feign/契约**无按 openid/userName 批量查询端点** | **需 PM 拍板方案 ①②③**（推荐 ②，见 §2.2） |
| **C3** | 贡献榜分组键 | §4.3「出题贡献榜」未指定分组键；任务书 §2.2「按 created_by 分组」 | `created_by` 存 openid（= `auth_user.user_name`）；`settle_name` 为自由文本且样例 NULL | 分组键 **`created_by`**（与任务书一致）；**不用** `settle_name`（非用户标识）。需 PM 知悉 |
| **C4** | keyWord 空串语义 | 任务书 §2.1「空 keyWord 语义待 B-Review 定夺」 | — | 建议：缺字段 400；空串返回空列表（不 400）。需 PM 确认 |

## 4. 约束遵守声明

- 仅新增上述 2 端点（C2 若选方案 ② 则除外，需 PM 放行为 3 端点：2 subject + 1 auth 查询）。
- 不修改/不删除任何现有端点、字段、鉴权、错误码语义；不动 `api/` 快照与 `status/sync-manifest.json`。
- 风格对齐现有 `getSubjectPage` 范式：`ResponseResult` 包装、DTO `PageQuery` 风格（extends PageInfo）、description 中文。
- 示例值均为语义化样本（`keyWord=HashMap`、`topN=10`），无真实环境信息（规则 8）。

## 5. 关联与后续

- 任务书：`pm/requirements/2026-08-26/portal-phase1-backend-contract-proposal-task.md`（PR #66）
- 设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）
- 后续：PM 确认 proposal（含 C1-C4 决策）→ B-Impl 实现任务书 → 前端门户化任务书（F-Impl）；验收后快照全链同步（P1/P3 模式）

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-26