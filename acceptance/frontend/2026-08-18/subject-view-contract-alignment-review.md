# S2/S3 前端评审复核签署（subject 视图契约对齐 + 端到端）

> 复核角色：前端评审（F-Review）
> 复核日期：2026-08-18
> 任务书：`pm/requirements/2026-08-18/frontend-real-api-integration-task.md`（S2/S3）
> 实现 PR：前端仓库 `jackeywilders/CoderClubFront` **#7** `refactor(subject): align views with contract fields + end-to-end (PR-2/S2-S3)`

## 1. 复核结论

✅ **S2/S3 复核通过，同意合入。** 前端评审已合入 PR #7（2026-08-18T17:50:48Z，merge commit `ab60c04`）。

## 2. 规则 9 远端证据

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `3924dbc`（视图/类型契约对齐）、`7de780c`（判断题语义）、`683cd0d`（清理死代码） |
| 回执提交 SHA | 见 `handoff/frontend-to-backend/2026-08-18/subject-real-api-integration-report.md` 对应回执提交 |
| PR 号 | 前端仓库 #7 |
| R2 状态 | 已合入 `main`（`git merge-base --is-ancestor 3924dbc origin/main` ✓） |

## 3. 契约对齐核对（S2：字段与契约 schema 一致）

| 类型 | 契约 schema | 前端 `src/types/subject.d.ts` | 一致 |
| --- | --- | --- | --- |
| SubjectInfo | `SubjectInfoDTO`（id/subjectName/subjectDifficult/settleName/subjectType/subjectScore/subjectParse/subjectAnswer/categoryIds/labelIds/categoryId/labelId/labelName/optionList） | `SubjectInfo` 同字段 | ✅ |
| SubjectCategory | `SubjectCategoryDTO`（id/categoryName/categoryType/imageUrl/parentId/children，无 sort） | `SubjectCategory` 同字段 | ✅ |
| SubjectLabel | `SubjectLabelDTO`（id/labelName/sortNum/categoryId） | `SubjectLabel` 同字段 | ✅ |
| 选项 | `SubjectAnswerDTO`（optionType/optionContent/isCorrect） | `SubjectAnswerOption` 同字段 | ✅ |

`CategoryManage.vue`/`LabelManage.vue` payload 均用契约字段名（分类 `categoryName/categoryType/imageUrl`、标签 `labelName/categoryId/sortNum`）。

## 4. 判分与题型语义复核（S3）

- **单选**：正确答案选项 `isCorrect=1`，判分按 `optionList.isCorrect` 推导字母比对。✅
- **多选**：正确选项集合 `isCorrect=1`，判分按字母数组排序比较。✅
- **判断**：答案位于 `optionList[0].isCorrect`（1=对/0=错），`subjectAnswer` 仅简答使用；前端新建/编辑/判分三处语义一致（提交 `7de780c` 修正）。✅
- **简答**：参考答案走 `subjectAnswer`（表单 `subjectParse` 作为解析文本），不自动判分。✅
- 展示：`correctAnswerText` 单选/多选回显正确字母、判断回显"正确/错误"、简答回显答案。✅

## 5. 验证证据

- 前端 `ci` workflow `check` SUCCESS（GitHub Actions，含 npm test / lint / api:check / build）。
- 真实后端端到端（PR body + 联调证据）：admin 登录 → 分类树/分页/详情契约结构正确；单选/判断判分正确；user 403；OSS 上传 200。已由前端评审在 S4 回执（`handoff/frontend-to-backend/2026-08-18/subject-real-api-integration-report.md`）汇总。
- R2：合入后 `src/types/subject.d.ts` 在 main 存在，`3924dbc` 为 `origin/main` 祖先。

## 6. Review 非阻塞观察（留档，转后端回执/后续任务）

1. **P2 默认值**：`buildPayload` 补 `subjectScore: 0`（后端评审建议默认如 10）。@NotNull 可过，但 0 分语义待后端回执确认合理默认。
2. **P1 sort**：`CategoryManage` 表单保留 `sort:0` 随 payload 携带——契约 `SubjectCategoryDTO` 无该字段，后端 Jackson 默认忽略未知属性；待 PM 决策（后端补 `sort` vs 前端彻底移除）后收敛，当前不破坏。
3. **P3 subjectType**：`SubjectList`/`SubjectBrowse` 查询传 `subjectType`——后端已支持（`countByCondition`），契约 `SubjectPageQueryDTO` 未声明；已随 P3 提案待 PM 确认补声明，属"契约未声明参数的临时使用"，因走 `proposals/` 合规。
4. **重复定义**：`OPTION_LETTERS`/`optionLetter` 在 `SubjectEdit.vue` 与 `SubjectAnswerPanel.vue` 各一份，可后续抽 composable。
5. **文件细节**：`CategoryManage.vue` 末尾缺换行符（无功能影响）。

## 7. 关联交付

- S1 复核签署：`acceptance/frontend/2026-08-18/s1-subject-real-api-review.md`
- S4 双轨回执：`handoff/frontend-to-backend/2026-08-18/subject-real-api-integration-report.md` + `-summary.json`
- 契约疑问：`proposals/frontend/2026-08-18/interface-consistency-questions.md`（P1/P2/P3），后端回应 `proposals/backend/2026-08-18/interface-consistency-p1-p3-response.md`，待协调 PM 确认

## 8. 版本记录

- 2026-08-18：创建（S2/S3 前端评审复核签署）。