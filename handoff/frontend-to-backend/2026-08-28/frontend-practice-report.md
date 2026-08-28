# 前端阶段二练习实施回执（A8-P2：T1 练习列表页 + T2 答题页 + T3 分析报告页 + T4 门户练习榜 + 基线 63 端点）

> 回执角色：前端实现（F-Impl）
> 回执日期：2026-08-28
> 任务书：`pm/requirements/2026-08-28/phase2-frontend-practice-task.md`（派发 PR #88，`9abf347b`，taskId=A8-P2-FE）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）
> 契约快照：`2583b906…`（63 端点，零变更，本任务未改交接仓库 `api/` 快照与 `sync-manifest.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `feat/practice-a8-p2`（基于 main `cf9d460b` 重建，22 commits 一体交付） |
| 实施提交 SHA | `5c05279`（practice.ts）、`81a2e28`（types）、`5062d50`（utils）、`3179035`（PractiseQuestions）、`bcb407a`（PractiseDetail）、`561ddc0`（PractiseAnalytic）、`20f7f69`（SpecialPracticePanel）、`bf5a810`（PreSetPanel）、`6432814`（UnCompletePanel）、`2a56a8f`（PracticeQuestionPanel）、`047e69a`（AnswerCard）、`902718d`（PracticeTimer）、`b67db27`（SkillStarBar）、`0743c30`（ScoreDetailDrawer）、`00b1a14`（practice.test）、`0afaf8a`（routes）、`d57cbfe`（PortalLayout）、`ba050d3`（HomeView）、`3a91350`（response-interceptor）、`b9d4e77`（response-interceptor.test）、`69f4462`（package.json）、`d52a9a0`（base64 63） |
| 合并提交 SHA | `ed3c56a`（Merge pull request #15，mergedAt 2026-08-28T05:48:18Z，合入 = 用户） |
| PR 号 | 前端仓库 **#15** |
| R2 状态 | ✅ 已合入 `main`（远端核验：`main` HEAD = `ed3c56a`，API 通道） |
| 契约快照 SHA-256 | `2583b906…`（交接仓库当前快照，63 端点，本任务零变更） |

> 注：交付经 SDD 全流程（7 任务逐任务实现 + 任务级审查 + 3 轮修复收敛 + 全分支最终审查合并就绪）。推送因 git 通道（TUN 代理）不稳定，实施提交最终经 GitHub API（contents PUT，22 文件）重建于 `feat/practice-a8-p2`，22 文件 blob 与本地 final tip 逐字节核验一致。

## 2. T1 练习列表页（`src/views/practise/PractiseQuestions.vue` + 三面板）

- 路由：PortalLayout children 新增 `practise-questions`（练习）、`practise-detail/:practiceId`（在线答题）、`practise-analytic/:practiceId`（练习报告）。
- `PortalLayout.vue`：「练题」从占位菜单改为真实 `<router-link to="/practise-questions">`（保留「鸡圈」「模拟面试」占位）。
- `PractiseQuestions.vue`：顶部三标签切换（专项练习/模拟套卷/我未完成）+ 左侧大类 Menu（仅专项练习）+ 内容区，门户亮色卡片 1200px 居中。
- `SpecialPracticePanel.vue`：大类源 `queryPrimaryCategory({categoryType:0})`（D1 决策）→ 选中拉 `getSpecialPracticeContent({primaryCategoryId})` 树（`CategoryCountNodeVO[]`）→ 分类分组 + 标签 checkbox 勾选，`assembleIds = ["catId-labelId"]` → `addPractice({assembleIds})` 返回 practiceId → 跳 `/practise-detail/:practiceId`；切换大类清空已选 + 加载态。
- `PreSetPanel.vue`：`getPreSetContent({orderType,pageNo,pageSize})` 排序 radio（1名称/2最新/3最热）+ 分页；`PreSetItemVO` 无 `subjectCount`，显示 `setDesc`+`setHeat`（D7 决策）；「开始答题」→ `addPractice({assembleIds:[]})` → 跳答题页。
- `UnCompletePanel.vue`：`getUnCompletePractice({pageNo,pageSize})` + 分页；「继续答题」→ `/practise-detail/:practiceId?time=timeUse`（续做计时起点）。

## 3. T2 答题页（`src/views/practise/PractiseDetail.vue` + 三个组件）

- 布局（prototype 定稿「A 答题卡 + B 答题区」）：顶栏（返回退出/卷标题/计时器/交卷按钮）+ 左侧常驻 `AnswerCard` + 右侧全宽居中 `PracticeQuestionPanel`。
- `PracticeQuestionPanel.vue`：单选 el-radio / 多选 el-checkbox / 判断 el-radio（正确"1"/错误"0"）/ 简答 textarea+「本题目不计分」；`answerContent` 序列化 `"A"`、`"A,C"`（排序）、`"1"/"0"`、`trim()`；提交 `submitSubject` → `judgeable=true` 显示对错图标+背景、`judgeable=false`（简答）显示「已提交」（D4）。
- `AnswerCard.vue`：题型分区（单选/多选/判断/简答）+ 数字方块跳转 + 多色标识（当前蓝/答对绿/答错红/已提交未判琥珀/未答灰）+ 已答统计。
- `PracticeTimer.vue`：自实现 setInterval `HH:MM:SS`（零新依赖）+ 暂停/继续；续做从路由 `?time=` 续计（D3）。
- `PractiseDetail.vue`：路由 `practiceId` → `getSubjects({practiceId})`（回填 isAnswer/answerContent）→ 单题 `getPracticeSubject`；`subjectReqSeq`/`listReqSeq` 竞态令牌；交卷 `ElMessageBox.confirm → submit({practiceId,timeUse}) → 跳报告`；交卷后 400 → 静默（response-interceptor silent 标记）+ 页面「该练习已交卷」提示（消除双 toast）；返回退出 `router.back()`。
- `response-interceptor.ts`：新增 `isSilentRequest`（config.silent），`submit` 请求带 `silent:true` 跳过全局 toast（401/403 auth 处理不受影响）。

## 4. T3 分析报告页（`src/views/practise/PractiseAnalytic.vue`）

- 顶部统计：`getReport({practiceId})` → `totalCount/correctCount/correctRate`（正确题数/总题数/正确率）。
- 技能区：`skills[]` → `SkillStarBar`（`labelName` + `el-rate` 只读星级 `★×starLevel` + `correctRate%`）（D2 决策，零新依赖不引 ECharts）。
- 答题明细 Tab：`ScoreDetailDrawer`（el-drawer + `defineExpose({open})`）调用 `getScoreDetail({practiceId})`，点击题号 → `getSubjectDetail({practiceId,subjectId})` 内联展示 `isCorrect`/我的答案/正确答案/解析/标签。
- 底部「练习其他技能」→ `/practise-questions`。
- loading / skills 空 / error+重试 4 态齐全。

## 5. T4 门户首页练习榜（`src/views/home/HomeView.vue`）

- 右栏「综合练习榜」占位替换为 `getPracticeRankList({topN:10})` → `RankItemVO[]`（头像/昵称 `nickName||userName`/练习次数）；**空数组不渲染该区段**（`v-if="rankList.length>0"`）；贡献榜保留。

## 6. 配套：前端契约基线 63 端点同步

- 前端基线 `docs/frontend/handoff/api-docs-baseline.json` 更新：`specSha256` = `2583b906…`、`endpointCount` = 63（新增 13 practice + 4 subject/internal = 17 端点）。
- `npm run api:check`：SHA `2583b906…`、63 endpoints、No changes（通过）。
- `src/api/practice.ts` 新增 13 端点；`src/types/practice.d.ts` 13 DTOs+11 VOs；`src/utils/practice.ts` 5 纯函数（formatTime/parseTime/serializeAnswer/starLevel/buildAssembleIds）。

## 7. 验证结果

| 命令 | 结果 |
| --- | --- |
| `npm run build`（vue-tsc + vite） | exit 0 |
| `npm test` | 24/24 pass（含 14 条练习纯函数用例） |
| `npm run api:check` | No API contract changes detected（63 endpoints，SHA 2583b906） |
| `npm run lint` | exit 0 |
| CI（PR #15 `check`） | conclusion=success |
| 审查 | 7 任务任务级审查全部通过（Task 3/4/6 触发修复轮全部收敛）；全分支最终审查合并就绪 |

## 8. 已知待联调确认项

1. `correctRate` 量纲（0-100 vs 0-1）：全链路按 0-100 口径实现（starLevel/`Math.round()`），需与后端返回核对（联调时确认）。
2. `ScoreDetailDrawer.numClass`：简答未判分且 `isCorrect=false` 时显示语义待后端核实（未判分简答按琥珀「未判分」的兜底）。
3. 专项练习 `getSpecialPracticeContent` 响应为 `CategoryCountNodeVO[]` 递归树（D1 决策），与参考 jc-club-master 旧版响应不同（请求体需 `primaryCategoryId`）。
4. 组件级单测覆盖 util 纯函数；交互/竞态以类型检查 + 审查 + 时序推演覆盖（零新依赖，未引 vitest）。

## 9. Frontend 声明

我确认以上消费文件、来源、哈希和验证结果真实可复核；未确认的字段、方法、鉴权或错误码没有被前端自行推断。

- Frontend 角色：前端实现（F-Impl）
- 日期：2026-08-28