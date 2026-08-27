# A8 阶段二 practice 练题域——表结构差异分析（B-Review）

> 角色：后端评审（B-Review）
> 日期：2026-08-27
> 任务书：`pm/requirements/2026-08-27/phase2-practice-contract-proposal-task.md`（PR #80 v2）
> 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§6（Q4 全 Feign / Q5 P0+P1 同批）
> 表结构基线：云端核验（与 `doc_jc-club-init.sql` 一致）；practice 4 表 + subject 既有表

## 1. 任务 0：subject 域 internal 端点清单（Q4 数据访问边界定稿）

practice **不直连 subject 表**；题目能力收敛 subject 域内部端点（标注 internal、不对外宣传，同 `list-by-identifiers` 定位）。定稿 **4 个 internal 端点**：

| # | 端点（建议路径，final 以提案为准） | 语义 | 消费方 |
| --- | --- | --- | --- |
| I1 | `POST /subject/internal/random-subjects` | 按 assembleIds（`catId-labelId`）+ 排除集 + 数量 + 题型配比（单选/多选/判断）随机抽题 → 返回题目 id 集（`order by rand()`，量级小不建索引） | practice addPractice / interview start（简答限定） |
| I2 | `POST /subject/internal/category-count` | 专项练习内容：大类→分类→标签树 + 各有题量标记（`primary_category_id` 过滤 + `subject_mapping` 计数） | practice getSpecialPracticeContent |
| I3 | `POST /subject/internal/subjects-by-ids` | 按题目 id 集取题干/选项（不含答案）+ 判分所需答案数据（结构化，供判分与题干渲染） | practice getSubjects/getPracticeSubject/getSubjectDetail/判分 |
| I4 | `POST /subject/internal/judge` | 提交作答（题目 id/类型/答案集）→ subject 域按题型规则判分返回对错（**判分规则唯一实现**，复用现有题型 Service/Handler，见 §5） | practice submitSubject |

> internal 端点与既有 `list-by-identifiers` 一样：登录鉴权 + 标注 internal 仅内部消费，不写入 C 端对外宣传位。

## 2. 表结构基线（云端核验，与 schema 文档一致）

| 表 | 关键列 | 字符集 |
| --- | --- | --- |
| `practice_set` | set_name / set_type(1实时生成 2预设) / set_heat / set_desc / primary_category_id | utf8mb4_bin |
| `practice_set_detail` | set_id / subject_id / subject_type | utf8mb4_bin |
| `practice_info` | set_id / complete_status(1完成 0未完成) / time_use("HH:mm:ss") / submit_time / correct_rate(decimal 10,2) / created_by | utf8mb4_bin |
| `practice_detail` | practice_id / subject_id / subject_type / answer_status / answer_content(varchar 64, 排序逗号串) | utf8mb4_bin |

## 3. 差异分析结论（对照参考 12 接口，每点三选一）

| # | 差异点 | 结论 | 明细 |
| --- | --- | --- | --- |
| 1 | 套卷列表排序（orderType） | **现有表支持（无 DDL）** | `set_heat`（最热）+ `created_time`（最新）+ `set_type=2`（预设过滤）两字段够用；默认排序 = `set_type=2` + `created_time DESC`（或 id DESC）；无需新增字段 |
| 2 | 专项练习（assembleIds 语义） | **现有表支持（无 DDL）** | `addPractice` 时生成实时套题：`practice_set`（set_type=1, primary_category_id=assembleIds 中大类）+ `practice_set_detail`（组装题目）；assembleIds 为请求参数不作持久化列 |
| 3 | 未完成判定/续做 | **现有表支持（无 DDL）** | `complete_status=0` 判定足够；续做 = 请求带 `practiceId`（非空即回填已答 `practice_detail.subjects` 状态）；首进建草稿（time_use=00:00:00） |
| 4 | 排行聚合（getPracticeRankList） | **现有表支持（无 DDL）** | `practice_info` 按 `created_by` 分组、`COUNT(*)`（complete_status=1）降序 + Feign `auth list-by-identifiers` 取昵称头像；无需新表/列 |
| 5 | 报告与解析（getReport/getScoreDetail/getSubjectDetail） | **现有表支持（无 DDL）** | `practice_detail`（answer_status/answer_content）+ internal I3（题目/选项/答案/解析）内存聚合；subject 域 `querySubjectInfo` 详情可复用（含答案），见 §4 冲突点 C5 |
| 6 | 字符集 | **无需迁移** | practice 4 表 utf8mb4_bin（云端核验），subject/auth 关联表 utf8mb4——字符串比对（如 answer_content）按列级 collation 正常 |
| 7 | **判分能力收敛（新增）** | **需 subject 域扩展（无 DDL，属实现设计）** | 现有 `AbstractSubjectTypeHandler` 仅 `add/queryBySubjectId`，**无判分能力** → 见 §5 收敛方案；简答不自动判分语义需明示 |

## 4. 与 A8 设计/架构方向冲突点（明示交 PM 决策）

| # | 冲突点 | 设计表述 | 后端现状/差异 | 建议 |
| --- | --- | --- | --- | --- |
| **C5** | 答案详情数据源 | 架构 §6.2 #11 `getSubjectDetail`「选项含 isCorrect/正确答案/我的答案/解析」 | 契约 `getSubjectPage` 响应不返回 `subjectAnswer`（含简答，契约 200 描述明确）；`querySubjectInfo/{id}` 详情含选项与 `subjectAnswer`（A8-P1 search 同样不带 answer） | 建议 `getSubjectDetail` 走 subject internal I3（含答案数据，internal 消费）；`getSubjectPage`/search **不加** answer（保持现有 C 端列表不带答案语义）。需 PM 确认 internal 取舍 |
| **C6** | 报告标签聚合 | 架构 §6.2 #9「按标签聚合正确率 → 技能星级」 | practice 4 表无标签关联；`practice_detail` 仅有 subject_id/subject_type | 需经 internal I3（subject 侧返回题目标签）内存聚合——subject 侧 `subject_mapping` 可反向查标签；无 DDL。需 PM 知悉实现路径 |
| **C7** | 简答判分 | 架构 §6.2「submitSubject 单题提交判分」 | 简答无自动判分（现有无判分；参考 jc-club 亦手写退化） | 建议 internal I4 对 `subjectType=4` 简答返回「不判分」语义（answer_status=0 或标记待人工），practice 交卷正确率按可判分题目计算（分母剔除简答）。需 PM 确认口径 |

## 5. 判分收敛方案（差异第 7 点，Q4 落地）

- **扩展** `AbstractSubjectTypeHandler`：新增抽象方法 `JudgeResult judge(Long subjectId, String answerContent)`（或 `List<String>` 答案集）：
  - `RadioTypeHandler`：单选——`isCorrect` 选项比对（答案 = 正确选项标号）
  - `MultipleTypeHandler`：多选——字母数组**排序后集合相等**比对（注意 practice_detail.answer_content 为排序逗号串，varchar 64 够用）
  - `JudgeTypeHandler`：判断——对/错比对
  - `BriefTypeHandler`：简答——返回「不判分」标记（不进入正确率分母，见 C7）
- **组织**：`SubjectTypeHandlerFactory` 按 `@SubjectTypeAnno` 分发（既有机制，零重构）→ domain service 统一判分入口 → internal I4 端点。
- **practice 侧不实现任何判分逻辑**（与 jc-club 手写 if/else 反模式划清界限）。
- 判分结果仅返回对错（boolean/isCorrect），不暴露答案（internal C 端不可见）。

## 6. DDL 变更清单

**无**。全部差异点现有 4 表支持；practice 仅新增代码与 internal 端点，无表/列/索引变更（`order by rand()` 组卷量级小，不建索引——B 组评估项）。

## 7. giveUp（放弃）纳入判定

**纳入**（可选端点，建议同批）：`POST /practice/detail/giveUp`——软删 `practice_detail`（is_deleted=1）+ `practice_info`（is_deleted=1），返回 Boolean；鉴权登录。理由：门户「放弃练习」交互需要；实现成本低；与状态机不冲突（放弃后未完成列表自然消失）。**结论：纳入提案（可选优先级 P2）**。

## 8. 关联

- 本次差异分析结论随提案 `proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md` 一并提交。
- C5-C7 + giveUp 纳入与否 → PM 决策（连同 DDL=0 结论）。

---
- 分析角色：后端评审（B-Review）
- 日期：2026-08-27