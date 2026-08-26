# A8 前端门户化设计（鸡翅CLUB 门户重构 + 后端域方向）

> 日期：2026-08-26（Asia/Shanghai）
> 状态：**已批准（grill-me 九项决策逐项确认）→ 本稿落盘**
> 来源：grill-me 讨论（Q1-Q9 全部用户确认）；参考项目 `jc-club-front-master`（鸡翅CLUB，React 系）深度勘察结论
> 待办关联：A8（原「SubjectBrowse 门户化（方向 A）」扩展为本设计全盘门户化）
> 说明：本稿为设计规格（`docs/superpowers/specs/` 标准输出），不替代 `proposals/`——所有契约新端点在实施前仍须走 `proposals/` + PM 确认；后续用 brainstorming/writing-plans 分阶段落实现计划（未开始）。

---

## 1. 背景与目标

当前前端（CoderClubFront）为**后台管理形态**（dashboard 侧边栏 + 9 组路由：subject 浏览/答题/分类/标签/列表/编辑 + user/role/permission 管理），面向 B 端管理操作。目标：参照参考项目「鸡翅CLUB」（React 18 + AntD 5 门户：顶部 Header + 1200px 内容区、题库即首页、练题/鸡圈/模拟面试模块）重构为 **C 端门户形态**：

- **保留 Vue 3 + Element Plus 技术栈**（Q1：不换 React；参考项目借鉴信息架构/页面结构/交互形态，不搬代码；参考项目自身含大量死代码，仅作功能清单与形态参照）。
- **全盘重构、分阶段执行**（Q2/Q9）：四阶段推进，每阶段契约变更走 proposal 闭环。
- 后端现状：仅 auth/subject/file 三域有能力（契约 43 端点）；DB 25 张表全齐，practice/interview/share 域未实现——后端方向一并纳入本设计（Q8）。

## 2. 决策记录（grill-me 九项，均已确认）

| # | 决策点 | 结论 |
| --- | --- | --- |
| Q1 | 技术栈 | 保留 Vue 3 + Element Plus，门户化重构（参考项目 React/AntD 仅为形态参照） |
| Q2 | 阶段一边界 | 门户壳 + 题库浏览链路门户化（题库首页/刷题/搜索）；管理页原样保留 |
| Q3 | 登录形态 | 账密 + 扫码双通道 |
| Q4 | 扫码实现 | 无微信平台资源 → 占位（契约 `/auth/wx-login` 已存在；前端入口 UI + 后端骨架，公众号资源就绪后联调；真实凭据约定占位符、不落库） |
| Q5 | 题库首页结构 | 三栏照搬：左分类三级联动 / 中题目列表（全题型 1-4、难度 3 档、分页）/ 右「出题贡献榜」+「综合练习榜」占位 |
| Q6 | 刷题页交互 | 保留「做题判对错」+ 同页上一题/下一题翻页；点赞/收藏延后 |
| Q7 | 门户壳 | Header（Logo「鸡翅CLUB」+ 主菜单四项[刷题上线，练题/鸡圈/模拟面试占位] + 全局搜索框 + 用户菜单[个人资料/管理后台/退出]）；管理端保留 dashboard 布局分离 |
| Q8 | 后端方向 | 域优先级 practice → share → interview；interview 的 AI 能力先 mock（规则/关键词 + 题库随机抽题 + 简单评分），后续可替换真实 AI |
| Q9 | 阶段划分 | 四阶段总表（below）；每阶段 = proposal → 后端实现 → 回执验收 → 前端实现 → 回执验收 闭环 |

## 3. 阶段划分总表

| 阶段 | 内容 | 后端配套 | 前端交付 | 依赖/备注 |
| --- | --- | --- | --- | --- |
| **一（门户化）** | 门户壳（Header/路由/用户菜单）+ 三栏题库首页 + 刷题页（判对错 + 翻页）+ 搜索页 + 扫码登录占位 | 补 2 端点：`POST /subject/getSubjectPageBySearch`、`POST /subject/getContributeList` | 门户布局重构；3 页改造/新增；管理端保留原 dashboard | 无外部依赖；点赞延后 |
| **二（练题域）** | 练习列表（专项/套卷/未完成）、答题页（计时/答题卡/交卷）、分析报告（得分/雷达图/解析） | practice 域约 12 端点（表已齐） | 3 页门户化新写 | 依赖阶段一壳 |
| **三（社区域）** | 鸡圈页（发动态/图片/圈子/评论/无限加载） | share 域约 5 端点（表已齐 + sensitive_words 过滤） | 1-2 页新写 | 依赖阶段二顺序 |
| **四（面试域 + 收尾）** | 模拟面试三页（简历上传解析/作答/历史详情）+ 个人中心门户化 + 点赞 + upload 题目门户化 | interview 域约 5 端点（**AI 先 mock**）；`subjectLiked` 点赞对 | 3+ 页新写 + 体验优化 | mock 方案阶段四前定；隐私项可穿插 |

补充规则（已认可）：管理端（subject 管理、user/role/permission）长期维持 dashboard 分离形态；阶段四隐私项（个人中心/点赞/upload 门户化）可在阶段二/三间隙穿插。

## 4. 阶段一详细设计

### 4.1 门户壳（PortalLayout，新建）

- 顶部 Header：Logo「鸡翅CLUB」+ 主菜单四项（刷题=活跃；练题/鸡圈/模拟面试=占位，点击提示「开发中，敬请期待」）+ 全局搜索框（回车 → `/search?t=关键词`）+ 用户菜单（个人资料 → 现有 `/user/profile` 沿用；管理后台 → dashboard 管理入口；退出 → `/auth/logout`）。
- 内容区 1200px 居中；明色主题（亮色 + 白卡 + 分类彩卡，对齐参考项目视觉基调，Element Plus 默认蓝为主色）。
- 未登录态：无 userInfo → 跳 `/login`（参照现有行为）。

### 4.2 路由组织（阶段一）

- 门户布局下：`/`（题库首页）、`/subject/answer/:id`（刷题页，沿用现有路径）、`/search`（搜索页，新增）、`/login`（门户视觉登录页）。
- 管理布局保留原路由全集（`/subject/category|label|list|edit/*`、`/user/profile|manage`、`/role/manage`、`/permission/manage`、`/dashboard`、404）；**原 `/subject/browse` 从管理布局移除**——其浏览功能由门户首页 `/` 承接，管理端浏览经 `/subject/list` 覆盖（不保留双入口）。

### 4.3 题库首页（门户首页）三栏

| 栏 | 内容 | 数据源（契约现有） |
| --- | --- | --- |
| 左 | 分类三级联动：大类卡片（横向滑动 + 多彩卡）→ 二级分类 → 三级标签 | `queryPrimaryCategory` → `queryCategoryByPrimary` → `queryLabelByCategoryId`（**零新增，组合调用**；不补参考项目的 `queryCategoryAndLabel` 合并接口） |
| 中 | 题目列表：全题型（1 单选/2 多选/3 判断/4 简答）、难度 3 档（1 简单/2 中等/3 困难）、分页 | `getSubjectPage`（A2 已收窄的 6 字段：pageNo/pageSize/subjectDifficult/categoryId/labelId/subjectType） |
| 右 | 「出题贡献榜」+「综合练习榜」占位 | 贡献榜 = 新端点 `getContributeList`；练习榜占位（阶段二启用） |

### 4.4 刷题页（/subject/answer/:id）

- 保留现有「做题判对错」交互（SubjectAnswerPanel：单选/多选/判断与正确答案比对 + 解析）。
- 新增同页「上一题/下一题」翻页：**路由查询参数携带列表上下文**（`/subject/answer/:id?page=1&categoryId=&labelId=&subjectType=&subjectDifficult=`），刷新可恢复原列表位置；翻页在同页内切换题目（先消费当前结果集，越界时按上下文重新拉取）。内存级列表缓存为后置优化，阶段一不引入。
- 退出按钮保留（A10 已合入）；点赞/收藏交互延后。

### 4.5 搜索页（/search，新增）

- Header 搜索框 → `/search?t=关键词`；结果列表（题干摘要 + 分页），点击跳刷题页；空态提示。
- 后端语义（proposal 待定推荐）：`keyWord` 匹配 `subjectName` + 题干关键词（LIKE），分页 + 分类可选，**不扩大范围**（不做全文检索/拼音等）。

### 4.6 登录与扫码占位

- 登录页门户化视觉；账密登录沿用（A10 已对齐 userName/nickName）。
- 扫码：前端登录页「微信扫码登录」入口（占位按钮 + 提示），后端 `wx-login` 端点按契约骨架实现（真实公众号配置就绪前返回明确的「未配置」语义，不伪造成功）；公众号资源到位后联调（真实凭据占位符约定、不落库）。

### 4.7 阶段一测试

- 后端：`SubjectContractTest` 回归（51/52 基线不回归）+ 新端点 contract 用例（search/contribute 参数与空结果）。
- 前端：现有 subject 全链路回归（列表/答题判分/分类管理）+ 门户壳路由（登录态/未登录态跳转）+ 搜索页（结果/空态）。

## 5. 后端方向（阶段二～四）

- **practice（阶段二）**：表已齐（practice_info/set/set_detail/detail）。实施前 B-Review 先做「表结构 vs 参考接口语义」差异分析（如 orderType 排序字段、未完成判定字段等），差异走 proposal 补列。
- **share（阶段三）**：表已齐（share_circle/moment/message/comment_reply）+ sensitive_words 过滤；图片走 OSS（契约已具 `oss/upload`）。
- **interview（阶段四，AI 先 mock）**：mock 形态 = 简历解析关键词/规则匹配、出题从题库随机抽取、评分简单规则（正确率等）；`interview_history`/`interview_question_history` 表承载；后续可替换真实 AI（接口语义不变）。
- 参考项目接口语义清单（实现 benchmark，见勘察记录）：practice 12 / circle 5 / interview 5。

## 6. 契约与治理配套

- **阶段一新增端点（2）**：`/subject/getSubjectPageBySearch`、`/subject/getContributeList`——**批量单 proposal（建议一个 proposal 文件含 2 端点）**，B-Review 起草 → PM 确认 → B-Impl 实现 → 快照同步（P1/P3 模式，语义差异 +N）。
- **阶段二～四新端点**（约 22 个）：每阶段一批 proposal（一批多端点），避免 22 次单端点往返。
- 快照同步节奏：每阶段验收后走「源 SHA → 快照新 SHA → pm.json/sync-manifest 全链 + 语义差异计数」既有模式。
- 标签/分类联动零新增（§4.3 组合方案）。

## 7. 待细化 / 待决策清单（补充讨论点）

| # | 项 | 性质 | 建议（默认值） |
| --- | --- | --- | --- |
| 1 | 搜索语义范围 | 待决策（影响体验） | `subjectName` + 题干 LIKE；不扩全文检索 |
| 2 | 刷题翻页上下文传参 | **已定**（见 §4.4） | 路由查询参数携带列表上下文，刷新可恢复；内存缓存后置 |
| 3 | 左栏大类卡片横向滑动实现 | 实现期（视觉细节） | Element Plus 无内置 Swiper：自实现横向滚动容器（CSS scroll-snap），不引入 swiper 依赖 |
| 4 | 题库列表返回条数 | 实现期 | 分页默认 20 条/页（对齐参考项目页容量） |
| 5 | 空态/占位文案 | 实现期 | 占位菜单提示「开发中，敬请期待」；搜索空态「很抱歉，没有找到相关题目」 |
| 6 | 登录页注册入口显眼度 | 待决策（门户化后） | 保留现有注册链路入口，视觉弱化为次级链接（门户以登录为主） |
| 7 | interview mock 规则细节 | 阶段四前定，挂起 | 不阻塞 practice/share |
| 8 | sensitive_words 词库来源与维护 | 后端设计期 | 内置默认词库 + 后续管理接口（阶段三） |
| 9 | 上传题目门户化（贡献题目） | 已挂阶段四 | 沿用 `subject:add` 权限门禁语义（契约 `/subject/add` 已有） |
| 10 | 阶段一前端执行主体 | 已定 | 前端实现（F-Impl）派发；后端 2 端点先于前端（B-Impl） |
| 11 | 点赞（subjectLiked）接口 | 已延后 | 阶段四与个人中心一起做（表 subject_liked 已存在） |
| 12 | 视觉伴侣/主题细节 | 可后置 | 门户配色/彩卡按参考项目基调走 Element Plus 实现，如需原型可视化另启讨论 |

## 8. 关联与事实依据

- 参考项目勘察（深度）：`G:/Dev/backend/Club/jc-club-front-master`（React 18 + AntD 5；14 路由/9 模块；接口清单与死代码标注见勘察会话）
- 当前前端：CoderClubFront（Vue 3 + Element Plus；dashboard 管理形态；A10 清理执行中）
- 当前后端：CoderClub（auth/subject/file 有能力；契约 43 端点全列表见勘察）
- 契约快照：`api/coderclub-openapi.json`（`8ebcda53`，18 语义差异）
- 治理：`AGENTS.md`（规则 6/8/9）、`docs/agents/verification-workflow.md`、`proposals/` 流程