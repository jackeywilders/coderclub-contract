# Proposal：A8 阶段二 practice 练题域契约（批量提案：12 practice + 4 subject internal）

> **提案角色：** 后端评审（B-Review）
> **日期：** 2026-08-27
> **任务书：** `pm/requirements/2026-08-27/phase2-practice-contract-proposal-task.md`（PR #80 v2，提交 `be797988`）
> **差异分析：** `designs/backend/2026-08-27/phase2-practice-diff-analysis.md`（同批提交）
> **架构方向：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §6（Q4 全 Feign / Q5 P0+P1 同批）
> **状态：** 待 PM 确认

## 1. 范围与边界

- 新增 **16 端点**（一次批量提案）：practice 域 12 个（P0 答题链 + P1 报告/排行，同批）+ subject 域 internal 4 个（I1-I4）+ 可选 `giveUp`（P2，差异分析 §7 纳入）。
- practice 域为**新模块**（模块级实现由 B-Impl 任务书定：`coder-club-practice` 新聚合模块，含 api/app/domain/infra/starter，参照 auth/subject 四层）。
- **数据访问边界（Q4）**：practice 不直连 subject 表；题目读/判分全经 internal 端点。
- 不修改/删除任何现有端点、字段、鉴权、错误码语义；未动 `api/` 快照与 `sync-manifest`；DDL 变更 = **无**（差异分析 §6）。

## 2. subject 域 internal 端点（任务 0，4 个）

> 标注 internal，仅内部 Feign 消费，不对外宣传（同 `list-by-identifiers` 定位）；鉴权 = `@SaCheckLogin` + 内部调用；错误码沿用现有体系。

### 2.1 `POST /subject/internal/random-subjects`

| 项 | 定义 |
| --- | --- |
| 请求 | `InternalRandomQueryDTO`：`assembleIds: List<String>`（必填，格式 `catId-labelId`）、`excludeSubjectIds: List<Long>`（可选）、`count`（integer）、`typeCountMap: Map<Integer,Integer>`（可选：题型配比，如 {1:10,2:6,3:4}） |
| 语义 | `subject_mapping.category_id-label_id IN (assembleIds)` + `is_deleted=0` + NOT IN 排除集 + `order by rand() limit count`，按 typeCountMap 配比抽样；配比空 → 全量随机 |
| 响应 | `ResponseResult<List<Long>>`（题目 id 集；不足按实际数量） |
| internal | ✅ 仅 practice/interview 消费 |

### 2.2 `POST /subject/internal/category-count`

| 项 | 定义 |
| --- | --- |
| 请求 | `InternalCategoryCountQueryDTO`：`primaryCategoryIds: List<Long>`（必填，大类） |
| 语义 | 大类→分类→标签树 + 各节点题目量（`subject_category` parent 链 + `subject_mapping` count，`is_deleted=0`）；有题量才算（题量 = 该分类/标签下题目数） |
| 响应 | `ResponseResult<List<CategoryCountNodeVO>>`：`{categoryId, categoryName, categoryType, parentId, subjectCount, children[]}`（树形） |
| internal | ✅ 仅 practice getSpecialPracticeContent 消费 |

### 2.3 `POST /subject/internal/subjects-by-ids`

| 项 | 定义 |
| --- | --- |
| 请求 | `InternalSubjectsByIdsQueryDTO`：`subjectIds: List<Long>`（必填，`@Size(max=500)`）、`withAnswer: Boolean`（默认 false——判分链路置 true 取答案数据） |
| 语义 | `subject_info` + 关联题型子表（radio/multiple/judge/brief）按 id 集批量取题；`withAnswer=false` → 题干/选项（不含正确答案）；`true` → 含正确答案/解析（供判分与 getSubjectDetail） |
| 响应 | `ResponseResult<List<InternalSubjectItemVO>>`：`{id, subjectName, subjectType, subjectDifficult, optionList[{optionType,optionContent,isCorrect}], subjectAnswer, subjectParse, categoryIds, labelIds, labelName}` |
| internal | ✅ practice getSubjects/getPracticeSubject/getSubjectDetail/判分消费 |

### 2.4 `POST /subject/internal/judge`

| 项 | 定义 |
| --- | --- |
| 请求 | `InternalJudgeQueryDTO`：`subjectId`（必填）、`subjectType`（1/2/3/4）、`answerContent`（string，判分维度） |
| 语义 | 按题型规则判分（**唯一判分实现**，复用 `AbstractSubjectTypeHandler` 扩展方法 + `SubjectTypeHandlerFactory` 分发）：单选 = 正确选项标号比对；多选 = 字母数组排序后集合相等；判断 = 对错比对；**简答 = 不判分**（返回 `judgeable=false`） |
| 响应 | `ResponseResult<JudgeResultVO>`：`{judgeable: boolean, isCorrect: boolean}`（简答 judgeable=false） |
| internal | ✅ practice submitSubject 消费 |

## 3. practice 域 C 端端点（12 个 + giveUp）

> 统一：`@SaCheckLogin`（门户登录墙）；`ResponseResult` 包装；错误码沿用（401/400/业务错误 BaseException）；示例语义化（规则 8）。

### P0 答题链

| # | 端点（POST /practice/...） | 请求 | 响应 | 语义要点 |
| --- | --- | --- | --- | --- |
| 1 | `set/getSpecialPracticeContent` | `SpecialContentQueryDTO{primaryCategoryId}` | `ResponseResult<List<CategoryCountNodeVO>>`（复刻 internal I2 结构） | 专项练习内容：大类→分类→标签树（有题量）；经 internal I2 |
| 2 | `set/addPractice` | `AddPracticeDTO{assembleIds:List<String>, practiceId?:Long}` | `ResponseResult<Long>`（practiceId 或 setId） | 开始/续做专项：经 internal I1 组装（**续做 practiceId 存在则直接返回草稿**）；新建草稿 practice_info（complete_status=0, time_use=00:00:00）+ practice_set/set_detail |
| 3 | `set/getSubjects` | `GetSubjectsDTO{setId?, practiceId?}` | `ResponseResult<List<PracticeSubjectItemVO>>`（不含答案；含 isAnswer/answerContent 回填） | 套卷题目列表（含续答回填）；首进由 addPractice 建草稿；经 internal I3 |
| 4 | `set/getPracticeSubject` | `GetPracticeSubjectDTO{subjectId, practiceId}` | `ResponseResult<PracticeSubjectItemVO>`（不含答案） | 单题内容 |
| 5 | `set/getPreSetContent` | `PreSetContentQueryDTO{orderType:1名称 2最新 3最热, pageNo, pageSize}` | `ResponseResult<PageResult<PreSetItemVO>>`（setId/setName/setDesc/setHeat/subjectCount） | 预设套卷列表（set_type=2）；差异 §3.1 排序 |
| 6 | `set/getUnCompletePractice` | `UnCompleteQueryDTO{pageNo, pageSize}` | `ResponseResult<PageResult<UnCompleteItemVO>>`（practiceId/setId/setName/timeUse/completeStatus） | 未完成练习分页（complete_status=0 + is_deleted=0） |
| 7 | `detail/submitSubject` | `SubmitSubjectDTO{practiceId, subjectId, subjectType, answerContent}` | `ResponseResult<SubjectJudgeResultVO>`（`{isCorrect}`；简答 judgeable=false） | 单题提交：Feign internal I4 判分 → 落 practice_detail（answer_status/answer_content 排序逗号串）→ **update-or-insert 幂等** |
| 8 | `detail/submit` | `SubmitPracticeDTO{practiceId, timeUse}` | `ResponseResult<Boolean>` | 交卷：**先补未答差集记录（answer_status=0 空内容）再算 correct_rate**（修正 jc-club 先算后补 bug）→ complete_status=1 + submit_time + `set_heat+1`；简答不进分母（C7 口径） |

### P1 报告/排行（同批交付）

| # | 端点 | 请求 | 响应 | 语义要点 |
| --- | --- | --- | --- | --- |
| 9 | `detail/getReport` | `ReportQueryDTO{practiceId}` | `ResponseResult<ReportVO>`：`{totalCount, correctCount, correctRate, skills:[{labelName, correctRate}]}` | 评估报告：正确 n/m + 按标签聚合正确率→技能星级（经 internal I3 取标签，C6 路径） |
| 10 | `detail/getScoreDetail` | `ScoreDetailQueryDTO{practiceId}` | `ResponseResult<List<ScoreDetailItemVO>>`：`{subjectId, subjectType, answerStatus, answerContent, isCorrect}` | 答题明细 |
| 11 | `detail/getSubjectDetail` | `SubjectDetailQueryDTO{practiceId, subjectId}` | `ResponseResult<SubjectDetailItemVO>`：选项含 isCorrect/正确答案/我的答案/解析/标签 | 单题答案详情；经 internal I3 withAnswer=true（C5 决策） |
| 12 | `detail/getPracticeRankList` | `RankListQueryDTO{topN?}`（默认 10 上限 20） | `ResponseResult<List<RankItemVO>>`：`{userName, nickName, avatar, practiceCount}` | 综合练习榜：practice_info 按 created_by count（complete_status=1）降序 + Feign `list-by-identifiers` 昵称头像 |
| 13 | `detail/giveUp`（P2 可选） | `GiveUpDTO{practiceId}` | `ResponseResult<Boolean>` | 放弃：软删 practice_detail + practice_info（is_deleted=1）；差异 §7 纳入 |

## 4. 错误码与通用约定

- 鉴权：全部 `@SaCheckLogin`（无登录态 401）；internal 端点同登录墙 + 仅内部消费（业务服务不向 C 端暴露 internal 路径宣传）。
- 校验：Jakarta Validation + subject-common `Groups` 或 practice 域自有分组；缺必填 → 400；分页参数复用 `PageInfo`（pageNo 默认 1/pageSize 默认 20，语义同 `getSubjectPage`）。
- 错误码：不新增错误码；业务异常用 `BaseException(code, message)`（如「练习不存在」「题目不存在」→ 既有 400 类业务错误），全局处理器统一。
- 并发/幂等：submitSubject update-or-insert（practice_id+subject_id 唯一化判定）；submit 补差集在事务内。

## 5. 待 PM 决策项（差异分析 C5-C7 + giveUp）

| # | 项 | 建议 | 需 PM 确认 |
| --- | --- | --- | --- |
| C5 | getSubjectDetail 答案数据来源 | 经 internal I3 withAnswer=true；`getSubjectPage`/search 保持不带答案 | ✅ |
| C6 | 报告标签聚合 | subject internal I3 返回标签，practice 内存聚合（无 DDL） | ✅ |
| C7 | 简答判分口径 | 简答不判分（judgeable=false），正确率分母剔除简答 | ✅ |
| G1 | giveUp 纳入 | 纳入（P2 可选端点） | ✅ |
| D0 | DDL 变更 | 无（现有 4 表全支撑） | ✅ 知悉 |

## 6. 约束遵守声明

- 仅新增上述端点；未改既有端点/字段/鉴权/错误码；未改 `api/` 快照与 `sync-manifest`（PM 验收后全链同步 +16 语义差异）。
- internal 端点语义完整（请求/响应/鉴权/错误码/示例均有）；practice 全 Feign 数据访问（Q4 合规）。
- 示例均为语义化样本（`assembleIds=["1-3"]`、`topN=10`），无真实环境信息（规则 8）。

## 7. 关联与后续

- 任务书：`pm/requirements/2026-08-27/phase2-practice-contract-proposal-task.md`（PR #80）；架构方向 PR #79 §6
- 差异分析：`designs/backend/2026-08-27/phase2-practice-diff-analysis.md`
- 后续：PM 确认（含 C5-C7/G1/D0）→ B-Impl 实现任务书（practice 新模块 + subject internal，与网关任务线并行）→ 回执 → 签署 → 验收 → 快照全链同步 → 前端阶段二（F-Impl）

---
- 提案角色：后端评审（B-Review）
- 日期：2026-08-27