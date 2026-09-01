# 任务书：阶段四 interview 前端（F-Impl，门户面试页 + 管理端词库管理页）

> 派发角色：协调 PM
> 派发日期：2026-08-31
> 执行角色：前端实现（F-Impl）
> 决策依据：grill 共识 10 项 + brainstorming 设计确认（分节批准，2026-08-31）；后端任务书 `interview-implementation-task.md`（同批并行，B-Impl）
> **ES 决策：不引入 Elasticsearch**（后端已评估登记，前端无涉）
> 批次：阶段四独立批次；本批与 B-Impl 后端任务书两线并行

## 前置基线

- 前端项目 `G:/Dev/backend/Club/CoderClubFront`；角色分支 `impl/frontend`，建议实现分支 `feat/frontend-interview`。
- 消费契约：后端 interview 端点登记后的快照（**75 → 83 路径**，PM 验收后微同步；本任务书按 8 端点契约实现，基线更新随后端合入后的快照）。
- 管理端页面模式基准 = `SensitiveManage.vue`（操作卡 + 表格 + 对话框；词库页复用 `CategorySelect` 与 `utils/sensitive.ts` 的 `formatCreatedTime`）；门户模式基准 = `CircleView.vue`（分类选择/列表）+ **`PractiseDetail.vue`（逐题作答即时反馈）** 组合复用（PortalLayout 登录墙内）。

## 1. 任务明细

### F1 门户：面试流程（`/interview` 路由，PortalLayout 登录墙内）
- **开始面试**：分类选择（复用 subject 分类树/`CategorySelect`，可选「全部」）→ `POST /interview/start` → 题面列表（`InterviewStartVO.questions:[{questionId, subjectName, labelNames}]`，**`labelNames` 为字符串数组**）
- **逐题作答**：简答输入框 → `POST /interview/submit` → 即时评分反馈（`score` 0-100 + `scoreText` 三档文案 + 命中关键词展示）
- **结束**：`POST /interview/finish` → 汇总页（总分/平均分/`scoreText`/题数）
- **历史**：`POST /interview/history` 分页列表 → `POST /interview/history/detail` 详情（每题题目/我的答案/评分/命中词）
- 业务失败（HTTP 200 + code=400）内联展示（silent 能力沿用）；401 登录墙/403 既有处理

### F2 管理端：面试词库管理（`/interview-keyword` 或等价路由，MainLayout + `roles:['admin_user']`）
- 列表：分类筛选 + 全量表格（`interview_keyword`：分类/关键词/权重/创建时间，`createdTime` null → 「—」）
- 新增：对话框（分类选择 + 关键词输入 + 权重可选），同分类同词幂等（后端兜底）
- 删除：单行/批量删除 + 确认弹窗（与敏感词管理交互同构）
- 菜单：Sidebar 新增「面试词库」项（`v-if="hasAdminRole"`）

### F3 公共层
- `src/api/interview.ts`（5 面试端点 + 3 词库端点消费）、`src/types/interview.d.ts`（契约类型）、`src/utils/interview.ts`（纯函数：**scoreText 三档边界 `<60 基础待加强 / 60-79 掌握良好 / ≥80 理解深入`**、命中词展示、列表解析等，配单测）
- **`npm test` 脚本为显式文件枚举**：新增 `src/__tests__/interview.test.ts` 后必须加入 `package.json` test 脚本（否则新用例不执行、零回归声明失真）
- `api:check` 基线更新（75 → **83**，specSha256 随后端快照登记后同步）

## 2. 质量门禁与验收证据

1. `api:check` 基线更新并保持通过（No changes）；build / lint / 单测（含 interview 纯函数用例，既有用例零回归）/ CI SUCCESS。
2. 云端网关联调（回执登记）：登录墙 → start → submit（命中/未命中各一，`scoreText` 文案核对）→ finish → history/detail；管理端词库 save/list/remove + 403 非管理员。
3. 回执双轨：`handoff/frontend-to-backend/` 按创建日期（Markdown + `*-summary.json`，**含 `receiptCommitSha`**）+ 完成通知四字段；PR 由用户/F-Review 在 CI 绿后合入（仓库惯例）。

## 3. 约束

- 消费契约以后端登记的 interview 快照为准；发现契约问题先写 `proposals/frontend/` 交 PM，不得改基线绕过评审。
- 门户/管理端既有页面零改动（仅新增）；**不引入 ES**；规则 8 占位符（示例文案语义化）、Conventional Commits。

## 4. 关联

- 后端任务书 `interview-implementation-task.md`（同批并行）· grill 共识（PR 派发批次）· 管理端先例 `SensitiveManage.vue` · 门户先例 `CircleView.vue`
