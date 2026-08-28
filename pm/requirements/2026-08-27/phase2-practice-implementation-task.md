# 任务书：A8 阶段二后端实现（practice 新模块 13 端点 + subject internal 4 端点）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-27
> **执行角色：** 后端实现（B-Impl）
> **复核角色：** 后端评审（B-Review）
> **提案：** `proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）
> **决策：** `pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`（C5-C7/G1/D0 已确认）
> **架构：** `docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §6（Q4 全 Feign / Q5 P0+P1）
> **并行：** 网关任务（GW-1）执行中——完成网关后经网关验证本任务端点

## 1. 目标

实现阶段二练题域：新建 `coder-club-practice` 聚合模块（四层：api/app/domain/infra/starter，参照 auth/subject）+ subject 域 4 个 internal 端点；source 文档登记 17 端点（已批准，作实现一部分更新 `docs/api/coderclub-openapi.json`；交接仓库 `api/` 快照与 `sync-manifest` 由 PM 验收后全链同步，**你不得修改**）。**无 DDL**（差异分析 D0）。

## 2. 实施边界（仅 proposal 17 端点，禁止扩大）

### 2.1 subject 域 internal 端点（4 个，并入 coder-club-subject）

- `POST /subject/internal/random-subjects`（I1）：assembleIds（catId-labelId）/excludeSubjectIds/count/typeCountMap 配比随机抽题 → `List<Long>`
- `POST /subject/internal/category-count`（I2）：大类→分类→标签树 + 题量节点（`CategoryCountNodeVO` 树形）
- `POST /subject/internal/subjects-by-ids`（I3）：id 集批量取题（`@Size(max=500)`）；`withAnswer=false` 不含答案 / `true` 含答案与解析（判分与答案详情共用通路，C5）
- `POST /subject/internal/judge`（I4）：判分——**复用现有 `AbstractSubjectTypeHandler` + `SubjectTypeHandlerFactory`**（判分规则唯一实现）；单选标号比对/多选排序集合相等/判断对错/**简答 judgeable=false（C7）**
- internal 定位：仅 Feign 消费，不向 C 端宣传（契约登记完整）

### 2.2 practice 模块 13 端点（P0 8 + P1 4 + giveUp 1）

- 按提案 §3 逐一实现（详见 proposal 表：请求/响应/语义要点）
- **硬条件**：
  1. 数据访问全 internal Feign（Q4：practice 不直连 subject 表）
  2. 交卷口径（决策 C7/§3.2）：**先补未答差集记录（answer_status=0 空内容），再算 correct_rate**（修正参考实现先算后补 bug）；简答不进分母
  3. 幂等：submitSubject update-or-insert（practice_id+subject_id 唯一判定）；submit 补差集事务内（`@Transactional`）
  4. 时间/内容语义：time_use "HH:mm:ss"、answer_content 排序逗号串、correct_rate decimal(10,2)
  5. 报告：I3 取标签 → 内存聚合正确率→技能星级（C6）；排行：practice_info count（complete_status=1）降序 + Feign list-by-identifiers 昵称头像；topN 默认 10 上限 20
  6. giveUp：软删 practice_detail + practice_info（is_deleted=1）
- 模块结构：`coder-club-practice`（api/app/domain/infra/starter）加入根聚合 pom（`<modules>`）；依赖 `coder-club-dependencies`/`coder-club-common`；分页复用 `PageInfo` 语义

## 3. 禁止事项

- 不修改/删除任何现有端点、字段、鉴权、错误码语义；不建表/不动 DDL
- 不改 `api/` 快照与 `status/sync-manifest.json` 及治理文件
- internal 端点不对外宣传（不写入前端基线/不引导 C 端消费）；判分逻辑不在 practice 内复制

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送后端仓库（Conventional Commits；建议 practice 模块与 subject internal 分提交/单 PR）。
2. 源文档 `docs/api/coderclub-openapi.json` 登记 17 端点（已批准），LF SHA before/after 记录；17 端点契约完整（请求/响应/鉴权/错误码/示例）。
3. 回执双轨落 `handoff/backend-to-frontend/2026-08-27/`：Markdown（来源与提交哈希、17 端点明细、internal 边界说明、测试证据、源文档 SHA、网关联调证据）+ `*-summary.json`（模板字段：`taskId=A8-P2-BE`、`contractSnapshotSha256=4bfb3c72`（当前值，验收后 PM 更新）、`verificationResult`）。
4. 完成通知带四字段告知 B-Review 复核签署，签署后转 PM 验收。

## 5. 验收标准

- [ ] 17 端点按提案/决策语义实现（含 C5-C7 口径、幂等、internal 边界）
- [ ] 判分唯一实现（I4 复用 Handler 工厂；practice 无复制判分）
- [ ] 测试：SubjectContractTest 57/57 不回归 + internal 4 端点用例；**PracticeContractTest 新建**（13 端点：草稿/续答/单题判分/交卷口径（补差集+简答剔除）/报告聚合/排行 topN/giveUp/401/400）；全量 mvn 回归绿
- [ ] 网关联调：17 端点经网关可达（登录 401/白名单无关——全部登录墙路径）、loginId 透传正常
- [ ] 源文档 17 端点登记完整，LF SHA before/after 记录
- [ ] 未改 `api/` 快照与 `sync-manifest`；未改既有端点；无 DDL
- [ ] 回执双轨 + 四字段远端证据

## 6. 关联

- 提案：`proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）
- 决策：`pm/reviews/2026-08-27/phase2-practice-endpoints-proposal-decision.md`
- 架构：`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md` §6
- 并行：网关任务书 `pm/requirements/2026-08-27/gateway-introduction-task.md`（GW-1）
- 后续：PM 验收 → 快照全链同步（+17，63 路径）→ 前端阶段二任务书（F-Impl：练习列表/答题页/分析报告；含「简答不计分」展示要求）