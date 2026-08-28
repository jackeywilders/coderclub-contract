# 任务书：阶段二前端实现（F-Impl：练习列表/答题页/分析报告/练习榜，A8-P2-FE）

> **派发角色：** 协调 PM
> **派发日期：** 2026-08-28
> **执行角色：** 前端实现（F-Impl）
> **复核角色：** 前端评审（F-Review）
> **设计依据：** `docs/superpowers/specs/2026-08-26-a8-frontend-portal-design.md`（PR #64）§3 阶段表；`docs/superpowers/specs/2026-08-27-a8-backend-architecture-direction.md`（PR #79）§6
> **后端就绪：** 快照 **63 端点**（`api/coderclub-openapi.json`，SHA `2583B906`，PR #86 已合入）——practice 13 端点 + internal 4 全可用，详情见 proposal `proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81）
> **网关就绪：** 统一入口（GW-1 已验收，vite proxy 单入口可配）；登录态经网关校验
> **前端现况：** 门户化已完成（A8-P1），门户布局 / 题库首页 / 刷题页 / 搜索页 / 门户登录均可用；基线 46 端点
> **决策引用：** 简答不判分且不进分母（C7，前端需展示「不计分」标签）

## 1. 目标

实现阶段二前端三页（练习列表/答题页/分析报告）+ 门户首页右栏练习榜启用 + 前端基线 63 端点同步，使门户可用练题全链路（选卷→作答→交卷→报告）。

## 2. 实施边界（仅以下范围，禁止扩大）

### T1 练习列表页（`/practise-questions`，门户布局内，新增）

三标签页切换（参考 jc-club-front-master `practise-questions` 布局形态）：

- **专项练习**：左侧大类 Menu（`getSpecialPracticeContent` 大类→分类→标签题量树）→ 右侧勾选标签 → 点击「开始练习」调 `addPractice(assembleIds)` → 跳答题页（`/practise-detail/:practiceId`）
- **模拟套卷**：`getPreSetContent(orderType:1 名称/2 最新/3 最热)` 卡片列表 + 分页（`setId`/`setName`/`setDesc`/`setHeat`/`subjectCount`），点击「开始答题」→ 建 `addPractice`（无 assembleIds 直接建）→ 跳答题页
- **我未完成**：`getUnCompletePractice` 卡片列表 + 分页，点击「继续答题」→ 跳答题页（带 `practiceId` 续做）
- 布局参照门户壳（1200px 居中、亮色卡片）

### T2 答题页（`/practise-detail/:practiceId?setId=?`，门户布局内，新增）

- 顶部：标题 + 计时器（自实现 HH:MM:SS 翻牌/文字，暂停功能可选；零新依赖）
- 题目区：`getSubjects`（卷内题目列表，回填已答状态）→ `getPracticeSubject` 单题内容（题干/选项，不含答案）
- 作答：单选 el-radio / 多选 el-checkbox-group / 判断 el-radio（正确/错误）；**简答 `subjectType=4` → 展示「简答题请输入答案」文本区域 + 下方标注「本题目不计分」（C7）**，提交后判分结果返回 `judgeable=false`，前端不展示对错
- 单题提交：`submitSubject(practiceId, subjectId, subjectType, answerContent)`，判分结果即时显示（isCorrect 图标 + 题干背景色变化；简答仅显示「已提交」）
- 答题卡：侧边栏/弹窗（题型统计 + 题号跳转 + 已答/未答标记）
- 交卷：确认弹窗 → `submit(practiceId, timeUse)` → 跳分析报告页
- 续做：路由带 `practiceId` → `getSubjects` 回填已答状态（`isAnswer`/`answerContent`→ 回显勾选状态）；**交卷后禁止提交由后端守卫返回 400**，前端展示提示
- **返回/退出**：左上角返回按钮（`router.back()` → 练习列表页）

### T3 分析报告页（`/practise-analytic/:practiceId`，门户布局内，新增）

- 顶部：正确题数/总题数/正确率（`getReport`：`totalCount`/`correctCount`/`correctRate` + `skills[]`）
- 技能雷达图：`skills[{labelName, correctRate, starLevel}]` → 雷达图展示（用 Element Plus 无内置雷达图——自实现或引用 ECharts/CDN 按需；**零新依赖原则下**，可参考现有图表方案或自实现星级展示条（不依赖第三方图表库）——推荐：星级用星级图标（`★`/`☆` 或 Element Plus Rating 组件）展示，不引入雷达图库；若确认引入 ECharts，需单独评估（不阻塞其他功能）
- 答题明细 Tab：`getScoreDetail`（题号/题型/对错）→ 点击题号 → 弹窗/展开 `getSubjectDetail`（含 `isCorrect`/我的答案/正确答案/解析/标签）
- 练习其他技能按钮 → `/practise-questions`

### T4 门户首页右栏综合练习榜启用

- 门户首页 `/` 右栏「综合练习榜」占位 → 替换为 `getPracticeRankList(topN=10)` 展示（昵称/头像/练习次数 /count）；无数据 → 空态（不展示该区段）
- 数据源：practice 第 12 端点（排行 SQL 聚合 + Feign 昵称），已就绪

### T5 前端基线 63 端点同步（必做）

- `docs/frontend/handoff/api-docs-baseline.json`：`specSha256` = `2583b906a445…`、`endpointCount=63`（新增 17 端点：13 practice + 4 subject internal——internal 标注不宣称 C 端消费，但基线需同步完整性）
- `npm run api:check` 通过（基线 SHA 更新记录）

## 3. 禁止事项

- 不修改后端、交接仓库 `api/` 快照、`status/sync-manifest.json` 及治理文件（契约快照 `2583B906` 零变更）
- 不引新依赖（计时器自实现；雷达图推荐星级展示条，不引入 ECharts 等新依赖）
- 不改答题判分行为（简答不计分语义由后端返回 `judgeable=false`，前端仅展示）；不改已有门户功能
- 不扩大范围：圈评论、点赞、收藏、WebSocket、个人中心门户化均不在本任务

## 4. 交付与回执（规则 9 双轨）

1. 实施提交推送到前端仓库（Conventional Commits；建议单 PR 按模块多 commit）。
2. 回执双轨提交到交接仓库 `handoff/frontend-to-backend/2026-08-28/`：Markdown（来源与提交哈希、T1-T5 逐项明细、路由/组件清单、基线同步证据、验证输出）+ 同目录 `*-summary.json`（模板字段：`taskId=A8-P2-FE`、`sourceProject=G:/Dev/backend/Club/CoderClubFront`、`contractSnapshotSha256=2583b906`（零变更）、`verificationResult`、`verificationDate`）。
3. 完成通知带规则 9 四字段（实施 SHA、回执 SHA、PR 号、R2 状态），告知前端评审复核签署；回执经 `claude/frontend-proposals` PR 合入交接仓库 main（governance-check 自动合并）。
4. 前端评审复核签署后通知 PM；PM 验收后推进阶段二收尾（state 评估 → gate3-a8-phase2-*）。

## 5. 验收标准

- [ ] T1-T4 全部落地：练习列表三标签页、答题页（含简答「不计分」展示 + 续做 + 交卷后 400 守卫提示）、分析报告页（星级 + 明细）、练习榜启用
- [ ] 基线 63 端点同步 + `npm run api:check` 通过（基线 SHA 更新）
- [ ] `npm run build`（vue-tsc + vite）exit 0、`npm test` 无回归 + 新增练习相关用例（练习列表/答题/分析报告等，范围实现期定并记录）、`npm run lint` exit 0
- [ ] 回执双轨落 `handoff/frontend-to-backend/2026-08-28/`，通知带四字段远端证据

## 6. 关联

- 后端 proposal：`proposals/backend/2026-08-27/phase2-practice-endpoints-proposal.md`（PR #81，端点语义明细）
- 后端验收：`acceptance/backend/2026-08-27/a8p2-practice-domain-implementation-acceptance.md`（PR #86）
- 网关验收：`acceptance/backend/2026-08-27/gw1-gateway-implementation-acceptance.md`（PR #86）
- 契约快照：`api/coderclub-openapi.json`（63 端点，`2583B906`）
- 前端评审复核：签署回执（`acceptance/frontend/2026-08-28/`）后转 PM 验收