# 前端评审签署：前端阶段二练习实施（A8-P2-FE，T1-T4 + 基线 63）

> **签署角色：** 前端评审（F-Review）
> **签署日期：** 2026-08-28
> **任务书：** `pm/requirements/2026-08-28/phase2-frontend-practice-task.md`（派发 PR #88，`9abf347b`，taskId=A8-P2-FE）
> **回执：** `handoff/frontend-to-backend/2026-08-28/frontend-practice-report.md` + `-summary.json`（PR #89 主体 / PR #90 receiptCommitSha 回填）
> **实现：** 前端仓库 PR #15（`feat/practice-a8-p2`，22 commits，merge `ed3c56a9`，2026-08-28T05:48:18Z）

## 1. 规则 9 远端证据（人链核验）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `5c05279`（api/practice.ts）、`81a2e28`（types）、`5062d50`（utils）、`3179035`（PractiseQuestions）、`bcb407a`（PractiseDetail）、`561ddc0`（PractiseAnalytic）、`20f7f69`/`bf5a810`/`6432814`（三面板）、`2a56a8f`/`047e69a`/`902718d`（答题组件）、`b67db27`/`0743c30`（报告组件）、`00b1a14`（测试）、`0afaf8a`/`d57cbfe`/`ba050d3`（路由/壳/首页）、`3a91350`/`b9d4e77`（interceptor+测试）、`69f4462`（package.json）、`d52a9a0`（基线 63） |
| 合并提交 SHA | `ed3c56a9`（Merge pull request #15） |
| 回执提交 SHA | `aa03fc6`（回执主体，PR #89；回填后同值；回执 commit `8a3beed` 追溯） |
| PR 号 | 前端仓库 **#15**；交接仓库 #89/#90 |
| R2 状态 | ✅ 均已合入 `main`（前端 main HEAD=`ed3c56a9`，API 通道核验；交接仓库 PR #89/#90 已合入） |
| 契约快照 SHA-256 | `2583b906…`（63 端点，api 文件实测 SHA-256 `2583b90679ed…`，零变更） |

> 流程注记：同分支曾出现 PR #13/#14（中间版本），#14 曾有合入记录（`2cf74d05`），最终经 #15 合入 `ed3c56a9`；经核验 main 历史不含 `2cf74d05` 残留，最终生效为 #15，无重复合入。

## 2. 复核结论

✅ **A8-P2-FE（T1-T4 + 基线 63）复核通过，同意签署。** 练习列表/答题/报告/练习榜四块 + 基线 63 端点同步均满足任务书验收标准；回执双轨齐全、证据链完整；已知待联调项已如实记录，不阻塞签署。

## 3. 人链核验明细（F-Review 逐项验证，API 通道 + 本地 blob 核对 + 四命令）

### T1 练习列表页 ✅

- 路由：PortalLayout children 新增 `practise-questions` / `practise-detail/:practiceId` / `practise-analytic/:practiceId`（main `routes.ts` 核验 ✓）。
- PortalLayout：「练题」从占位改真实菜单（`router-link to="/practise-questions"`，active 高亮 `/practise` 前缀）；「鸡圈/模拟面试」保留占位。
- `SpecialPracticePanel`：大类 `queryPrimaryCategory({categoryType:0})` → `getSpecialPracticeContent({primaryCategoryId})` 树 → `assembleIds=["catId-labelId"]` → `addPractice` → 跳答题页；切换大类清空已选 + 加载态。
- `PreSetPanel`：`getPreSetContent({orderType,pageNo,pageSize})` 排序 radio + 分页；无 `subjectCount` 显示 `setDesc`+`setHeat`（D7）。
- `UnCompletePanel`：`getUnCompletePractice` + 分页；「继续答题」携带 `?time=` 续做计时。

### T2 答题页 ✅

- `PractiseDetail`：`getSubjects` 回填 + 单题 `getPracticeSubject`；`subjectReqSeq`/`listReqSeq` 竞态令牌（旧响应丢弃）✓ 核验。
- 交卷：`ElMessageBox.confirm` → `submit({practiceId,timeUse})` → 跳报告；400 已交卷守卫（silent 静默 toast + 页面提示「该练习已交卷」）✓ 核验。
- `PracticeQuestionPanel`：单选/多选/判断（"1"/"0"）/简答（textarea +「本题目不计分」）；`serializeAnswer` 序列化（多选排序、简答 trim）；`judgeable` 对错图标 / 简答「已提交」。
- `AnswerCard`：题型分区 + 数字跳转 + 多色标识；`PracticeTimer`：自实现 setInterval（零依赖）+ `?time=` 续计（D3）。
- `response-interceptor`：`isSilentRequest(config.silent)` 交卷 400/网络错误静默（401/403 auth 不受影响）✓ 核验 + 单测覆盖。

### T3 分析报告页 ✅

- `getReport` → totalCount/correctCount/correctRate；`SkillStarBar`（el-rate 只读星级 + correctRate%，D2 零依赖）；`ScoreDetailDrawer`（getScoreDetail → 题号 → getSubjectDetail 内联对错/答案/解析/标签）；「练习其他技能」→ `/practise-questions`；loading/skills空/error+重试 4 态。

### T4 门户练习榜 ✅

- `HomeView` 右栏占位替换 `getPracticeRankList({topN:10})` → `RankItemVO[]`（头像 `nickName||userName` 首字母 + 次数）；**空数组不渲染**（`v-if="rankList.length>0"`）；贡献榜保留 ✓ 核验。

### 配套：基线 63 端点 ✅

- `api-docs-baseline.json`：`specSha256` = `2583b90679ed…`、`endpointCount=63`；`getReport`/`getPracticeRankList` 等新端点齐备 ✓。
- `src/api/practice.ts`：13 端点（set×7 + detail×6）全量核验 ✓；`src/types/practice.d.ts` 13 DTOs+11 VOs；`src/utils/practice.ts` 5 纯函数（formatTime/parseTime/serializeAnswer/starLevel/buildAssembleIds）✓。

## 4. 验证证据（本机四命令独立复验、blob 核验 + CI）

| 命令 | 本机结果（2026-08-28，`feat/practice-a8-p2` 分支） | CI |
| --- | --- | --- |
| `npm run build` | ✅ vue-tsc + vite exit 0 | ✅ |
| `npm test` | ✅ **24/24 pass**（含 silent 400/401 用例） | ✅ |
| `npm run api:check` | ✅ SHA `2583b90679ed…`，63 endpoints，No changes | ✅ |
| `npm run lint`（全量 `--fix=false`） | ✅ exit 0 | ✅ |
| 前端 CI `check`（PR #15） | — | ✅ SUCCESS（run 33145503223，2026-08-28T05:41:52Z） |

**blob 一致性抽检**：本地 `src/api/practice.ts`、`PractiseQuestions.vue`、`PracticeQuestionPanel.vue`、`utils/practice.ts` 的 git blob SHA 与 main 上文件 SHA **逐字节一致**（4/4）。

## 5. 已知待联调确认项（随回执 §8，不阻塞签署）

1. **correctRate 量纲（0-100 vs 0-1）**：当前按 0-100 口径实现（starLevel 阈值/`Math.round()`），需联调核对后端返回。
2. **ScoreDetailDrawer.numClass**：简答未判分且 isCorrect=false 时显示语义待后端核实（当前按琥珀「未判分」兜底）。
3. **getSpecialPracticeContent 响应为 `CategoryCountNodeVO[]` 递归树**（D1 决策，请求体需 `primaryCategoryId`），与参考旧版不同——按契约快照实现。
4. 组件级单测覆盖 util 纯函数；交互/竞态以类型检查 + 审查 + 时序推演覆盖（零新依赖，未引 vitest）。

**以上联调确认项建议 PM 转交后端评审联调核验口径后闭环。**

## 6. 签署意见

✅ **签署通过**。A8-P2-FE（T1-T4 + 基线 63）实施与回执满足任务书验收标准，同意转协调 PM 验收（A8-P2 阶段收尾）。

## 7. 版本记录

- 2026-08-28：创建（前端评审签署，转 PM 验收）。