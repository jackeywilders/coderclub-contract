# A8 阶段三 circle 社区域（A8-P3-BE）——后端评审复核签署

> 角色：后端评审（B-Review）
> 签署日期：2026-08-30
> 任务书：`pm/requirements/2026-08-29/phase3-circle-implementation-task.md`（PR #95）
> 提案/决策：`proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`（PR #94）、`pm/reviews/2026-08-29/phase3-circle-endpoints-proposal-decision.md`（X1-X6/D0）
> 回执：`handoff/backend-to-frontend/2026-08-30/backend-a8p3-circle-domain-report.md` + `-summary.json`（PR #97，head `101b900`）
> 工作底稿：`designs/backend/2026-08-30/a8p3-circle-review-workpaper.md`
> 状态：**签署通过，转 PM 验收**

## 1. 复核结论

✅ **复核通过，签署本回执。** 实施 `d9eb64f`（CoderClub PR #15，18 commits = 3 携带 + 15 实现——回执"17/14"笔误随签署勘误）经人链核验与独立复验与提案/决策相符：

- [x] **11+2 端点完整**：circle 11（圈子树 1 / 动态 3 / 评论 3 / 消息 2 / 敏感词管理 2）+ X1/X2 既有端点扩展；74 路径逐一登记，快照 `2583b906` 零漂移
- [x] **DFA 方案 A′**：volatile 不可变快照 + DCL 惰性加载 + 管理端触发无锁重建立即生效（E2）；黑名单命中拒绝/白名单跳过
- [x] **X3 角色鉴权 403**：`@SaCheckRole("admin_user")` 双端点 + circle 注册 SaInterceptor/roleKeys 解析器（subject 先例）；`NotRoleException → 403` 显式映射（本系统首个实际生效的角色注解端点）
- [x] **消息语义**：from==to 不落（E4）、读取即已读幂等（is_read=2 条件更新 + 空页守卫）、中性文案 + 昵称读时组装（E3）、unRead 只计数
- [x] **评论树口径**：子树软删按 `softDeleteByIds` 实际受影响行数回减（同事务）；归属校验（动态仅本人 / 评论本人或动态作者，越权 400）；删除幂等 true
- [x] **X1/X2 向后兼容**：X1 两查询并集按 id 去重、超长数字串兜底不抛异常；X2 缺省零影响、展开经 subject_mapping（I2 同模式）、空集短路
- [x] **契约登记**：63→74 路径、96→117 schema；LF SHA `9EC37C66→736F6588`（`git show` 字节态独立计算，逐字一致）
- [x] **独立复验（本会话实跑）**：全量 `mvn install -DskipTests` exit 0；`CircleContractTest` **20/20**、circle domain **33/33**、`AuthContractTest` **13/13**（auth domain 40/40）、`SubjectContractTest` **73/73**——6 模块定向测试零失败
- [x] **云端 6 步联调证据**（回执 §5）：401 登录墙 + 预留路由 503→转实、圈子树、敏感词 save 立即可检、跨用户核心链状态机（发布→评论→回复→双账号未读→读取即已读 1→0→E4 自评不落→级联删除幂等）、DFA 400 业务错误

## 2. 规则 9 完成通知四字段（自检）

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `d9eb64f`（`d9eb64fb51c7ee5f22c947b4ee77c34574d38a1c`，18 commits） |
| 回执提交 SHA | `101b900`（PR #97 head，`claude/backend-a8p3-receipt`） |
| PR 号 | CoderClub PR #15——**已合入 main（merge `583b4bb`，2026-08-30，B-Review 复核通过后执行授权合入）** |
| R2 状态 | **实施 R2 达成**（已合入 CoderClub main）；回执 PR #97 与本签署随交接仓库流程合入 main |

## 3. 开放项处置与观察项（打包转 PM 验收，不阻塞）

| # | 项 | 处置标注 |
| --- | --- | --- |
| 1 | **C1：X1 消费侧键不匹配**（VO 无 id 字段，数字标识昵称降级标识串；"修复 practice 排行昵称"声明已由 B-Impl 撤回） | **随配套提案①闭环**（PM 已派发：`pm/requirements/2026-08-30/phase3-companion-proposals-task.md`，PR #99）；practice 排行昵称修复为该提案验收口径。本签署不阻塞 |
| 2 | **NotRoleException 映射缺口**（subject/practice 角色注解失败将 500） | **随配套提案②闭环**（同上）；circle 已示范修复 |
| 3 | 云端 403 未实测（单一 admin 测试账号） | 契约测试真实拦截链覆盖（`SaManager.setStpInterface` + SaInterceptor）；知悉 |
| 4 | 敏感词 remove→重建云端 e2e 未测（管理端无 list 端点，id 不可经 API 发现） | 单测覆盖重建链路；X6 圈子管理另案时一并评估 |
| 5 | `share_message.created_by` 落 null（蓝本同款，from_id 承载行为主体） | 知悉；如需对齐口径随后续提案 |
| 6 | `openapi` 头部 `info.description` 仍写"63 路径"（任务书冻结头部） | **提请 PM 在快照全链同步时一并授权更新为 74** |
| 7 | docker 容器级冒烟（本机无 Docker，延续 GW-1/A8-P2 验收补充项） | 有 docker 环境后随部署环节执行 `docker compose up --build`；容器注意钉时区 `TZ=Asia/Shanghai` |
| 8 | 后端仓库本机 worktree 现停于 `d9eb64f`（detached，B-Impl 会话遗留；R2 已合入不影响远端） | 由用户酌情切回 main |

## 4. 关联

- 任务书 PR #95 · 提案 PR #94 · 决策 X1-X6/D0 · 回执 PR #97 · 实施 CoderClub PR #15（merged `583b4bb`）
- 快照全链同步预期：63→74 路径（语义差异按实际登记，预计 38→51±）
- 后续：PM 验收 → 快照全链同步 → 前端阶段三任务书（F-Impl：鸡圈页）；配套提案（X1 VO 增补 + NotRoleException 映射）由 B-Review 按任务书（PR #99）另行起草

签署：后端评审（B-Review），2026-08-30
