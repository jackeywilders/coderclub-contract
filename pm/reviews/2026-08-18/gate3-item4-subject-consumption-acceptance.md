# Gate 3 事项 4 PM 验收：分类/标签/题目分页/详情/四题型/OSS 上传（前端消费）

> **验收角色：** 协调 PM（PM / 跨项目协调 Codex）
> **验收日期：** 2026-08-18
> **任务书：** `pm/requirements/2026-08-18/frontend-real-api-integration-task.md`（S1-S4）
> **实现 PR：** 前端仓库 `jackeywilders/CoderClubFront` **#6**（S1）、**#7**（S2/S3）
> **前审签署：** `acceptance/frontend/2026-08-18/s1-subject-real-api-review.md`（S1）、`subject-view-contract-alignment-review.md`（S2/S3）
> **S4 双轨回执：** `handoff/frontend-to-backend/2026-08-18/subject-real-api-integration-report.md` + `-summary.json`
> **验收结论：** ✅ **Gate 3 事项 4 通过（前端 subject 消费完成，解除 mock 并真实联调）；P1/P3 契约变更经决策后转后端实施，不阻塞本事项。**

## 一、核对依据（远程优先，R2 已核）

- 前端 `origin/main` 含 S1（`a855c06`）与 S2/S3（`ab60c04` 合并提交）合入；实施提交 `2724af4 / c068956 / 3924dbc / 7de780c` 均在 `origin/main`（`git merge-base --is-ancestor` 核 R2）。
- S4 summary 结构校验通过（impl `3924dbc`、PR #7、回执 `517b946`）。

## 二、路线图 Gate 3 事项 4 逐项核对

路线图原（Gate 3，事项 4）：**分类、标签、题目分页、详情、四种题型、OSS 上传**。

| 子项 | 证据（前端评审 S2/S3 + S4 回执） | 结论 |
| --- | --- | --- |
| 分类（tree/add/update/delete） | 契约 4 端点一致；`CategoryManage` 用契约字段（categoryName/categoryType/imageUrl） | ✅（sort 待 P1 决策后收敛，非阻塞） |
| 标签（list/add/update/delete） | 契约 4 端点一致；`LabelManage` 用 labelName/categoryId/sortNum | ✅ |
| 题目分页 | `getSubjectPage` 契约一致；`PageResult` 补 `totalPages` 对齐；`subjectType` 传参（P3 待补契约声明） | ✅（P3 决策后收口） |
| 题目详情 | `querySubjectInfo/{id}` 契约一致 | ✅ |
| 四种题型（单选/多选/判断/简答） | 判分语义逐一复核：单选 isCorrect 推导、多选字母数组比较、判断 optionList[0].isCorrect、简答 subjectAnswer 不回自动判分 | ✅ |
| OSS 上传 | 端到端 OSS 上传 200 | ✅ |
| （附加）认证/权限 | admin 登录 → 分类树/分页/详情正确；user 403 生效 | ✅ |

## 三、联调完成信号核对（任务书 §3）

- ✅ 后端日志可见前端真实请求（非 mock）：`src/api/subject.ts` `USE_MOCK` 引用数 = 0；dev 下经 vite proxy。
- ✅ 分页外壳/字段与契约一致：`PageResult` `list/total/pageNo/pageSize/totalPages`。
- ✅ 验证命令：前端 `ci` `check` SUCCESS（npm test / lint / api:check / build）。
- ✅ S4 回执落 disk（双轨，规则 9）。

## 四、已知待决/留档（不阻塞本事项关闭）

1. **P1 分类 `sort`**：本事项验收时 `CategoryManage` 带 `sort:0` 不破坏（后端 Jackson 忽略未知属性）；已按 PM 决策（方案 A）转后端补字段 + 契约声明，收敛后更新前端。见 `pm/reviews/2026-08-18/p1-p2-p3-interface-decisions.md`。
2. **P3 查询 schema 缺 `subjectType`**：已按 PM 决策补声明；整段 `getSubjectPage` 请求 schema 与运行时对齐后续单独提案。
3. **P2 `subjectScore` 默认值**：前端 add 补默认（后端评审建议 10），待后端回执确认合理默认（属前端适配，已决策）。

## 五、结论与后续

- **Gate 3 事项 4 验收通过。** 前端 subject 模块已解除 mock、真实对接已批准契约并端到端验证；Gate 3 其余事项（认证流转、权限树/动态路由/401/403、列表五态）在 S1-S3 已覆盖（见前审记录），本事项聚焦 subject 消费。
- **后续**：后端按 P1/P3 决策实施补字段与契约声明 → PM 同步 `api/` 快照全链 → 前端收敛 sort/subjectType → 视需 Gate 3 全项归拢 + Gate 4 发布门禁（需用户授权）。
- **状态文件**：`status/pm.json`、`status/frontend.json` 随本验收更新。

- 验收角色：协调 PM
- 日期：2026-08-18
