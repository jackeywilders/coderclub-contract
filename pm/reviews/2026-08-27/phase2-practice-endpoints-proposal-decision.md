# PM 决策：A8 阶段二 practice 契约提案确认（16+1 端点，C5-C7/G1/D0）

> 角色：协调 PM
> 决策日期：2026-08-27
> 提案：`proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）
> 差异分析：`designs/backend/2026-08-27/phase2-practice-diff-analysis.md`（同批）
> 状态：**确认通过；转 B-Impl 实现任务书**

## 1. 确认内容

| 项 | 确认 |
| --- | --- |
| 端点集 | **17 端点**（practice 12 P0+P1 + subject internal 4 + giveUp P2），一次批量 |
| subject internal | I1 random-subjects / I2 category-count / I3 subjects-by-ids（withAnswer 可切换）/ I4 judge——全 Feign 边界（Q4 合规），标注 internal 不对外宣传 |
| practice C 端 | 12 端点 + giveUp，P0/P1 同批（Q5 合规） |
| 数据访问 | practice 不直连 subject 表（全 internal Feign） |
| DDL | **无**（差异分析 D0：现有 4 表全支撑，报告标签聚合内存化） |
| 快照预期 | 46 → **63 路径**（+17），语义差异 21 → **38**（验收后全链同步） |

## 2. 决策项（C5-C7 / G1 / D0，按建议确认）

| # | 项 | 决策 |
| --- | --- | --- |
| C5 | getSubjectDetail 答案数据源 | 确认：internal I3 withAnswer=true 提供（判分链路与答案详情共用同一数据通路）；`getSubjectPage`/search C 端保持不带答案 |
| C6 | 报告标签聚合 | 确认：I3 返回标签 → practice 内存聚合正确率星级（无 DDL） |
| C7 | 简答判分口径 | 确认：简答不判分（judgeable=false），正确率分母剔除简答；**前端答题页需展示简答「不计分」提示**（阶段二前端任务书要求项） |
| G1 | giveUp | 确认纳入（P2 可选端点：软删明细 + practice_info） |
| D0 | DDL 变更 | 知悉：无 |

## 3. 关键质量点（回归风险提示，B-Impl 任务书硬条件）

1. **判分唯一实现**：I4 复用 subject 域 `AbstractSubjectTypeHandler` + `SubjectTypeHandlerFactory`（判分规则只此一处；practice 不复制判分逻辑）
2. **交卷口径修正**：先补未答差集记录，再算 correct_rate（修正参考实现先算后补的 bug）；简答不进分母（C7）
3. **幂等与并发**：submitSubject update-or-insert（practice_id+subject_id 唯一判定）；submit 补差集事务内
4. **internal 边界**：internal 路径不向 C 端宣传（契约登记完整但定位内部）

## 4. 后续链

1. B-Impl 实现任务书（本决策同批派发）：practice 新模块（api/app/domain/infra/starter）+ subject internal 4 端点；与网关任务线并行（网关完成后经网关验证）
2. B-Impl 回执 → B-Review 复核签署 → PM 验收 → 快照全链同步（+17）→ 前端阶段二任务书（F-Impl：练习列表/答题页/分析报告）
3. 云端真实验证（答题链/判分/报告/排行 + 网关链路）随验收衔接

## 5. 关联

- 提案：`proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）
- 架构方向：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§6
- 本决策：`pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`

决策：协调 PM，2026-08-27