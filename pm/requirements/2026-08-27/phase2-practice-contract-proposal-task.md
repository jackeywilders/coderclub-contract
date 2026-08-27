# 任务书：A8 阶段二练题域（practice）契约提案起草

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-27
> **执行角色：** 后端评审（B-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）§5（阶段二 practice，表已齐）与 §3 阶段表
> **参考语义：** 参考项目（jc-club-front-master）practice 域 12 接口清单（勘察记录）：getPreSetContent（套卷列表/orderType）、getSpecialPracticeContent（专项练习）、addPractice（开始练习）、getSubjects/getPracticeSubject（题目）、submitSubject（单题实时提交）、submit（交卷）、getReport（评估报告）、getScoreDetail/getSubjectDetail（答案解析）、getPracticeRankList（综合练习榜）、getUnCompletePractice（未完成）
> **状态：** A8 阶段一已闭环（gate3-a8-phase1-accepted）；阶段二启动

## 1. 目标

起草 A8 阶段二练题域的批量契约提案（practice 域端点 + 必要 DDL 差异分析结论），供 PM 确认后转 B-Impl 实现。**实施前先做「表结构 vs 参考接口语义」差异分析**（A8 设计 §5 要求），差异（如排序字段、未完成判定、排行聚合等）在提案中明示并以 proposal 补列。

## 2. 任务 1：表结构差异分析（交付物：分析结论，随 proposal 或单独 designs 文档）

云端库表结构已核验（与 schema 文档一致），基线如下：

| 表 | 关键列 |
| --- | --- |
| `practice_set` | set_name / set_type（1 实时生成 2 预设套题）/ set_heat（热度）/ set_desc / primary_category_id |
| `practice_set_detail` | set_id / subject_id / subject_type |
| `practice_info` | set_id / complete_status（1 完成 0 未完成）/ time_use / submit_time / correct_rate / created_by |
| `practice_detail` | practice_id / subject_id / subject_type / answer_status / answer_content |

差异分析要点（对照参考 12 接口）：
1. 套卷列表排序（参考 orderType：默认/最新/最热——`set_heat` 是否够用？是否需要 created_time 排序？是否需要新增字段？）
2. 专项练习（参考按大类 + 标签勾选组装题目——是否需要新表/新列？addPractice 的 assembleIds 语义落哪？）
3. 未完成判定（`complete_status=0` 是否足够？续做（practiceId 可选）语义？）
4. 排行（getPracticeRankList 聚合口径：按 practice_info 正确率/次数？需要 new 表/列？）
5. 报告与解析（getReport/getScoreDetail/getSubjectDetail 的数据来源是否现有表可支撑？subject 域已有 `querySubjectInfo` 可复用？）
6. 字符集注意：practice 系表 utf8mb4_bin（云端核验），无需迁移。

**结论形态**：每个差异点 = 「现有表支持 / 需补列（DDL 变更走 proposal 明示）/ 需新表」三选一；需 DDL 的项在提案中以「DDL 变更清单」章节列出（表/列/类型/注释），供 PM 决策（DB 变更执行按 A1 模式由用户/运维）。

## 3. 任务 2：契约提案（proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md）

- 批量提案全部 practice 端点（预计 10-12 个，按差异分析定稿），语义基准 = 参考 12 接口 + 本任务差异分析结论。
- 风格对齐现有提案范式（`ResponseResult` 包装、DTO PageQuery 风格、description 中文）；鉴权沿用 `@SaCheckLogin`（门户登录墙语义）。
- 请求/响应示例为语义化样本（规则 8）；不修改既有端点。
- 若差异分析发现方案需要分阶段（如排行/报告后置），可在提案中标注优先级（P0 核心答题链 / P1 报告排行），供 PM 排期。

## 4. 交付与回执（规则 9）

1. 差异分析结论 + 提案：落 `designs/backend/2026-08-27/`（分析）+ `proposals/backend/2026-08-27/`（提案），经 `codex/backend-contract` PR 合入交接仓库 main。
2. 完成通知带四字段告知 PM；PM 确认（含 DDL 变更项决策）后派发 B-Impl 实现任务书。
3. 发现的与 A8 设计冲突点明示交 PM（如接口语义与门户交互不符）。

## 5. 验收标准

- [ ] 差异分析 6 要点全部三选一结论，DDL 变更清单明确（表/列/类型/注释）
- [ ] 批量提案端点完整（请求/响应/鉴权/错误码/示例），风格对齐，无敏感信息
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改既有端点
- [ ] 合入 main + 通知四字段

## 6. 关联

- A8 设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（§3 阶段表 / §5 后端方向）
- 云端表结构核验：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md` §3（25 表与 schema 一致）
- 后续：PM 确认 → B-Impl 实现 → 回执 → B-Review 签署 → PM 验收 → 快照全链同步 → 前端阶段二任务书（F-Impl：练习列表/答题页/分析报告）