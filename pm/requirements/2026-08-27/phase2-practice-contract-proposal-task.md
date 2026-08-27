# 任务书：A8 阶段二练题域（practice）契约提案起草

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-27（v2 更新——吸收后端架构方向决策 Q4/Q5）
> **执行角色：** 后端评审（B-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）§5；`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§6（阶段二 practice 细则）
> **架构决策（Q4/Q5，本 v2 吸收）：** 数据访问 = **全 Feign 契约化**（题目读/判分/组装收敛 subject 域 internal 端点，practice 不直连 subject 表）；阶段二范围 = **P0 答题链 + P1 报告/排行同批全量**（12 端点一次提案，giveUp 可选由差异分析定）
> **参考语义：** 参考项目（jc-club-front-master 配套后端 jc-club）practice 域 12 接口清单（勘察记录）：getPreSetContent（套卷列表/orderType）、getSpecialPracticeContent（专项练习）、addPractice（开始练习）、getSubjects/getPracticeSubject（题目）、submitSubject（单题实时提交）、submit（交卷）、getReport（评估报告）、getScoreDetail/getSubjectDetail（答案解析）、getPracticeRankList（综合练习榜）、getUnCompletePractice（未完成）
> **状态：** A8 阶段一已闭环（gate3-a8-phase1-accepted）；阶段二启动

## 1. 目标

起草 A8 阶段二练题域的批量契约提案（practice 域端点 + 必要 DDL 差异分析结论），供 PM 确认后转 B-Impl 实现。**实施前先做「表结构 vs 参考接口语义」差异分析**（A8 设计 §5 要求），差异（如排序字段、未完成判定、排行聚合等）在提案中明示并以 proposal 补列。

## 2. 任务 0（新增，Q4 数据访问边界）：subject 域 internal 端点清单

practice **不直连 subject 表**；题目能力收敛 subject 域内部端点（标注 internal、不对外宣传，同 `list-by-identifiers` 定位）。差异分析/提案须包含以下 internal 端点的语义定义（最终形态与数量 B-Review 定稿，预计 3-4 个）：

| internal 端点（建议） | 语义 | 消费方 |
| --- | --- | --- |
| `随机抽题` | 按 assembleIds（catId-labelId）+ 排除集 + 数量（含单选/多选/判断配比）随机抽题返回题目 id 集 | practice addPractice / interview start（简答题限定） |
| `类目计数` | 专项练习内容：大类→分类→标签树 + 各有题量标记 | practice getSpecialPracticeContent |
| `批量取题` | 按题目 id 集取题干/选项（不含答案）与判分所需答案数据 | practice getSubjects/getPracticeSubject/判分 |
| `判分` | 提交作答（题目 id/类型/答案集）→ subject 域按题型规则判分返回对错（**判分规则唯一实现**，复用现有题型 Service/Handler） | practice submitSubject |

**差异分析第 6 点（字符集）保留**；新增第 7 点：**判分能力收敛**——subject 域现有题型服务（radio/multiple/judge/brief）如何复用组织为判分端点（含多选比对规则、判断、简答不判分语义），与 practice 提交链路衔接。

## 3. 任务 1：表结构差异分析（交付物：分析结论，随 proposal 或单独 designs 文档）

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

## 4. 任务 2：契约提案（proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md）

- 批量提案**全部 practice 端点（P0 答题链 + P1 报告/排行，约 12 个，Q5 同批全量）** + **subject 域 internal 端点（任务 0，3-4 个）**，语义基准 = 参考 12 接口 + 本任务差异分析结论；`giveUp`（放弃）纳入与否由差异分析定。
- 风格对齐现有提案范式（`ResponseResult` 包装、DTO PageQuery 风格、description 中文）；鉴权沿用 `@SaCheckLogin`（门户登录墙语义；internal 端点同登录 + 标注 internal 仅内部消费）。
- 请求/响应示例为语义化样本（规则 8）；不修改既有端点。
- 优先级标注：internal 端点与 practice P0 核心答题链为同批必做；P1 报告/排行与 P0 同批交付（不分阶段）。

## 5. 交付与回执（规则 9）

1. 差异分析结论 + 提案：落 `designs/backend/2026-08-27/`（分析）+ `proposals/backend/2026-08-27/`（提案），经 `codex/backend-contract` PR 合入交接仓库 main。
2. 完成通知带四字段告知 PM；PM 确认（含 DDL 变更项决策）后派发 B-Impl 实现任务书。
3. 发现的与 A8 设计/架构方向冲突点明示交 PM（如接口语义与门户交互不符）。

## 6. 验收标准

- [ ] 差异分析要点全部三选一结论（含任务 0 判分收敛第 7 点），DDL 变更清单明确（表/列/类型/注释）
- [ ] 批量提案端点完整（practice 12 全量 P0+P1 + subject internal 3-4：请求/响应/鉴权/错误码/示例），风格对齐，无敏感信息
- [ ] 数据访问边界符合 Q4（practice 无 subject 表直连设计），判分端点语义明确（复用题型 Service）
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改既有端点
- [ ] 合入 main + 通知四字段

## 7. 关联

- A8 设计：`docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（§3 阶段表 / §5 后端方向）
- **架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§6/§9 B 组**
- 云端表结构核验：`pm/reviews/2026-08-26/portal-phase1-search-contribute-proposal-decision.md` §3（25 表与 schema 一致）
- 后续：PM 确认 → B-Impl 实现（与网关任务线并行）→ 回执 → B-Review 签署 → PM 验收 → 快照全链同步 → 前端阶段二任务书（F-Impl：练习列表/答题页/分析报告）