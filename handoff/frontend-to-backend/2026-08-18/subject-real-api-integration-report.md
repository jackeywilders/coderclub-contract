# 前端 subject 真实 API 集成 S4 验收回执（前端评审）

> 回执角色：前端评审（F-Review）
> 回执日期：2026-08-18
> 任务书：`pm/requirements/2026-08-18/frontend-real-api-integration-task.md`（S1-S4）
> 依据：`docs/agents/verification-workflow.md` §6 双轨（Markdown + `*-summary.json`）

## 1. 来源与提交哈希

| 字段 | 值 |
| --- | --- |
| 来源项目 | `G:/Dev/backend/Club/CoderClubFront`（前端代码仓库，private） |
| 来源分支 | `main`（合入目标）→ `feat/subject-real-api-integration`（S1）、`feat/subject-view-contract-alignment`（S2/S3） |
| 实施提交 SHA（S1） | `2724af4` / `c068956` / `bbfa14c` |
| 实施提交 SHA（S2/S3） | `3924dbc`（视图/类型契约对齐）、`7de780c`（判断题语义修正）、`683cd0d`（清理死代码） |
| 前端 PR 号 | **#6**（S1）、**#7**（S2/S3），均已合入 `main`（merge `a855c06`、`ab60c04`） |
| R2 状态 | 已合入 `main`（`git merge-base --is-ancestor 3924dbc origin/main` ✓） |
| 契约快照 SHA-256 | `9a97c055…`（43 paths，未变） |

## 2. 复核结论

✅ **S1/S2/S3 复核通过**。subject 模块已解除 mock、切真实请求，视图与类型对齐契约，核心链路端到端可用，前后端契约疑问（P1/P2/P3）已走 `proposals/` 形成闭环。

## 3. 已验证接口清单（真实后端端到端，admin 会话）

| 接口 | 方法/路径 | 结果 | 说明 |
| --- | --- | --- | --- |
| 分类树 | GET `/subject/category/tree` | ✅ 200 | 返回结构 `id/categoryName/…/children`，前端树渲染正确 |
| 题目分页 | POST `/subject/getSubjectPage` | ✅ 200 | `PageResult` 外壳（list/total/pageNo/pageSize/totalPages）+ 列表项 `SubjectInfoViewDTO`（无装饰分页字段，M4-06 后） |
| 题目详情 | GET `/subject/querySubjectInfo/{id}` | ✅ 200 | 单选 `optionList[].optionType/optionContent/isCorrect` |
| 单选/多选选项 | （详情内） | ✅ | `isCorrect` 判定正确 |
| 判断题 | （详情内） | ✅ | 答案在 `optionList[0].isCorrect`，`subjectAnswer` 空 |
| 简答题 | （详情内） | ✅ | 解析经 `subjectParse`/答案经 `subjectAnswer` |
| 权限 403 | GET（user 会话） | ✅ 403 | 无权限用户被拦截，前端拦截器提示"无权限访问" |
| OSS 上传 | POST OSS | ✅ 200 | 契约字段上传可用（UI 接入留后续） |
| 鉴权 401 | 未登录请求 | ✅（S1 实测） | dev proxy 下 POST `/subject/getSubjectPage` → HTTP 401，拦截器清 token 跳登录 |

## 4. 联调环境与地址（占位符，规则 8）

- 联调环境：本地开发（vite dev server）
- 服务地址：经 vite proxy 转发——`/subject → <subject-svc>`、`/auth → <auth-svc>`、`/oss → <oss-svc>`（`<…>` 为占位符，真实地址见协调 PM 私有对照表 / 前端 `.env` 与后端 Nacos 配置）
- 前端 dev `VITE_API_BASE_URL=`（相对路径走 proxy）；生产 `VITE_API_BASE_URL=/api`（同域 nginx 反代）

## 5. 失败请求 / 响应与复现条件

- **无未解释的功能性失败**。两次预期内的"非 200"：未带鉴权 token 请求业务接口 → 401（拦截器处理，属正确行为）；user 角色访问 admin 资源 → 403（拦权限）。
- 复现条件：清除本地 token 后刷新业务页即可复现 401 跳转；使用普通用户角色登录访问题目管理即可复现 403。
- P1/P2 待回执字段（`sort` / `settleName` / `subjectScore`）当前由前端以默认值 + 标注过渡，不影响上述主链路。

## 6. 契约疑问闭环（P1/P2/P3）

- `proposals/frontend/2026-08-18/interface-consistency-questions.md`（前端实现，PR #26 已合入）
- 后端评审回应：`proposals/backend/2026-08-18/interface-consistency-p1-p3-response.md`（独立复核：P1 属实、P2 修正为仅 add 需 `subjectScore`、P3 属实并补充请求 schema 整段差异）
- 状态：**待协调 PM 确认方案**（P1 补 `sort` 或前端放弃；P3 补 `subjectType` 声明）。前端主体适配已按不依赖回执部分完成；待 PM 决策后由后续任务收敛。

## 7. 声明

- 本回执不修改 `api/` 快照、`status/sync-manifest.json`、后端项目；联调证据中的环境地址均以占位符呈现（规则 8）。
- `git diff --check` 通过；提交经交接仓库 PR 自动合入 `main`（governance-check 含证据门禁）。

## 8. 版本记录

- 2026-08-18：创建（S4 双轨回执；S1/S2/S3 复核结论汇总）。