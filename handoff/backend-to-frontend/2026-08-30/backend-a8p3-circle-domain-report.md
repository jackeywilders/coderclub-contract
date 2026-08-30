# 回执：A8 阶段三 circle 社区域实现（A8-P3-BE）

> **回执角色：** 后端实现（B-Impl）
> **日期：** 2026-08-30（Asia/Shanghai；落盘目录按治理规则 6 以创建日期为准，任务书原指定 2026-08-29/ 的偏差随完成通知交 PM 追认）
> **任务书：** `pm/requirements/2026-08-29/phase3-circle-implementation-task.md`（taskId=A8-P3-BE，PR #95）
> **提案：** `proposals/backend/2026-08-29/phase3-circle-endpoints-proposal.md`（PR #94）；决策 `pm/reviews/2026-08-29/phase3-circle-endpoints-proposal-decision.md`（X1-X6/D0）
> **设计/计划：** 后端仓库 `docs/superpowers/specs/2026-08-29-a8-p3-circle-domain-design.md`、`docs/superpowers/plans/2026-08-29-a8-p3-circle-domain-plan.md`（用户批准；DFA 方案 A′ 经权威源选型）

## 1. 来源与提交哈希

| 项 | 值 |
| --- | --- |
| 实现仓库 | jackeywilders/coderclub（后端） |
| 分支 | `feat/backend-a8-p3-circle` |
| 实现头 | `d9eb64f`（17 提交：3 携带 + 14 实现，含 3 轮审查修复） |
| PR | **#15**（feat/backend-a8-p3-circle → main，2026-08-29 开启） |
| CI | `build-and-test` ✅ + `sensitive-scan` ✅（run 33267186300） |
| 合入状态 | **R1 达成**（远端分支/PR 可见）；R2 待人工合入（约定：合入由用户/后端评审在 CI 全绿后执行） |

提交主题（14 实现提交）：骨架+BOM caffeine（R1 裁定含 cache starter）/ infra 五组 / 敏感词域 A′+X3 / 圈子树+缓存 / 动态域 / 消息域 / 评论域 / X1 / X2 / OpenAPI 登记（+1 修复轮）/ Dockerfile/compose/start（+1 修复轮）/ 最终审查修复波。

## 2. 端点明细（11 新增 + 2 扩展，对照提案逐条实现）

| # | 端点 | 提案语义要点 | 实现 ✓ |
| --- | --- | --- | --- |
| 1 | `GET /circle/share/circle/list` | 两层树（parent_id=-1 大类+子圈）；Caffeine TTL 30s（expireAfterWrite，TTL 过期为唯一失效路径） | ✓ `@Cacheable("circle:tree")` 于 domain impl；主类 `@EnableCaching`（Boot 4 CacheAutoConfiguration 为 `@ConditionalOnBean(CacheAspectSupport)`，实测必需——控制者裁定 R2） |
| 2 | `POST /circle/share/moment/save` | circleId 必须子圈（否则 400 非法圈子）；content/picUrlList 至少一项；敏感词黑名单命中拒绝；落 pic_urls JSON 串 + reply_count=0 + created_by=loginId | ✓ |
| 3 | `POST /circle/share/moment/getMoments` | 分页 created_time DESC,id DESC；picUrlList 反序列化；页内标识一次 Feign 批量组装，失败/缺失降级标识串 | ✓（实践降级先例同款） |
| 4 | `POST /circle/share/moment/remove` | 仅本人（否则 400 无权）；级联软删全部评论（事务）；重复删除幂等 true | ✓ `@Transactional(rollbackFor=Exception.class)`；动态已删不回减计数 |
| 5 | `POST /circle/share/comment/save` | replyType 1/2 语义；目标存在未删（400）；敏感词；消息落库（COMMENT→动态作者 / COMMENT_REPLY→被回复评论者；from==to 不落；targetId=动态 id）；reply_count 同事务 +1 | ✓；**最终审查增补**：type2 目标同属本动态校验（跨动态回复 400，复用「回复目标不存在」文案，无契约变化） |
| 6 | `POST /circle/share/comment/list` | 树形全量（回复套回复）；fromIsMomentAuthor（fromId==动态作者）；from/to 合并一次 Feign；孤儿不挂根（蓝本一致） | ✓；toId 为人员语义读时派生（type1=动态作者/type2=被回复评论者）——与实体 to_id 的 DDL 语义（type1=动态 id）刻意区分，OpenAPI 已按运行时口径登记 |
| 7 | `POST /circle/share/comment/remove` | 评论者本人或动态作者（否则 400）；组树收集目标+全部后代 ids → 事务内批量软删 → reply_count 按**实际更新条数**回减；幂等 true | ✓（按 softDeleteByIds 受影响行数回减，非集合大小） |
| 8 | `GET /circle/share/message/unRead` | Integer 未读总数（to_id=loginId 且 is_read=2），只计数不改状态 | ✓ |
| 9 | `POST /circle/share/message/getMessages` | isRead 可选过滤+分页 id DESC；content JSON 结构化展开（msgType/msg/targetId）+ 中性文案（"评论了你的动态"/"回复了你的评论"）+ from 昵称读时组装；**返回后按页内 ids 批量置已读**（幂等；空页守卫跳过置读——防 `id in ()` SQL 错误） | ✓ |
| 10 | `POST /circle/sensitive/words/save` | `@SaCheckRole("admin_user")`（403）；同词同类型幂等 true；成功后同步重建 DFA 立即生效 | ✓ |
| 11 | `POST /circle/sensitive/words/remove` | 同上；逻辑删幂等 true；成功后重建 | ✓ |
| X1 | `POST /auth/user/list-by-identifiers` | 纯数字串同时按 id 匹配，向后兼容；请求/响应结构零变化 | ✓ 实现口径=两次查询合并去重（`user_name IN 全部` ∪ `id IN 数字子集`，按 id 去重；数字串仍参与 name 匹配），规避 flex OR 分组语法风险，可观测语义与 OR 等价——B-Review 复核关注点 |
| X2 | `POST /subject/getSubjectPage` | 可选 `primaryCategoryId`：展开大类自身+直接子分类（显式不递归）经 subject_mapping 过滤，AND 叠加；缺省不生效 | ✓ count/list 双路径同步；缺省路径 SQL 等价有 toSQL 锚定；空集短路返回空页 |

**DFA 方案 A′（已批准）**：`WordContext` 构建后不可变 Trie 快照；`SensitiveWordDomainServiceImpl` 持 `volatile` 引用——DCL 惰性加载（CERT LCK10-J 规范形式）+ 管理端操作后无锁换引用重建（E2：修复蓝本重启才生效缺陷）；读路径零锁；不实现原地 addWord/removeWord 与定时刷新（YAGNI）。**bean 生命周期零查库**，保住 starter 无 DB 冒烟测试（CI 前提）。

**消息形态（Q6 决策 A）**：落库+拉取，无 WebSocket；`share_message.content` = JSON `{msgType,msg,targetId}`（fastjson2，BOM 2.0.61——控制者裁定 R2 用户批准引入）；is_read 1=已读/2=未读（蓝本口径），落库显式置 2。

## 3. 测试证据

- **CircleContractTest 20/20**（11 端点正例全覆盖含 comment/remove；401 未登录；403 非管理员（真实 SaInterceptor 注解链 + SaManager.setStpInterface）；400 矩阵：非法圈子/动态不存在/回复目标不存在/敏感词命中/越权；删除幂等；standalone MockMvc+Mockito，无 DB 依赖）
- **circle domain 单测 33/33**（WordFilter 4：黑命中/白跳过/重建生效/wordList；敏感词域 4：惰性加载仅一次/幂等/重建立即生效/remove 重建；圈子 1；动态 9；消息 6（含空页守卫）；评论 9（含跨动态 400））
- **AuthContractTest 13/13**（含 X1 结构回归用例）、auth-domain 40/40（含 X1 三用例：混合并集去重/纯非数字不触 id 查询/超长数字串不抛异常）
- **SubjectContractTest 73/73**（含 X2 缺省/生效两用例；既有 71 零回归）、subject 域单测 32/32（X2 展开/短路/null 路径 + toSQL 锚定）
- **全仓回归**：CI build-and-test `mvn install -DskipTests` + `mvn test` 全绿（run 33267186300）
- **审查链**：11 任务级审查（规格+质量双结论）+ 3 轮修复循环（task5 @Transactional / task10 toId 口径 / task11 Dockerfile 34 pom）+ 全分支最终审查（1 Critical 治理降级 + 2 Important + 1 Minor 修复波，定向复验 3/3 ADDRESSED）

## 4. 源文档登记（运行时权威契约源）

- `docs/api/coderclub-openapi.json`：**63 → 74 路径**、96 → 117 schema（13 业务 + 8 wrapper/错误 schema——后者系文档既有 `$ref` 包装风格的必然产物，审查已裁定正当）
- **LF SHA before/after：`9EC37C66…`（63 路径）→ `736F6588…`（74 路径，d9eb64f 最终值，提交正文含完整链）**
- X1/X2 语义与 schema 登记完成；`/auth/user/list-by-identifiers` 与 `getSubjectPage` 既有结构零变化
- 未动交接仓库 `api/` 快照与 `status/sync-manifest.json`（预期：63→74 路径、语义差异 38→51±，**PM 验收后全链同步**；快照 SHA 当前 `2583b906` 不变）

## 5. 网关联调证据（云端，2026-08-30）

环境：四服务本地启动注册云端 Nacos（namespace dev，配置由 Nacos 下发：DB/Redis 中间件地址）；gateway 5000 统一入口。逐条证据见后端仓库 `.superpowers/sdd/2026-08-29-a8-p3-circle-domain-plan/smoke-evidence.md`（本地工作区，凭据已脱敏）：

1. **无 token `GET /circle/share/circle/list` → 401**（网关登录墙；GW-1 预留路由 503 → 可达，**转实成立**）
2. 测试账号 `POST /auth/login` → token（32 位）
3. 带 token 圈子树 → **200** 两层树（Java圈子+4 子圈，叶子 `children:[]` 与文档口径一致）
4. 敏感词 save（中文词，UTF-8 文件体）→ **200 true**（测试账号为 admin_user；DFA 立即可检）
5. **核心链状态机**：user1 发布（200）→ getMoments（新动态在列，replyCount=0，createdTime epoch）→ **user2 评论（200）**→ comment/list（树形；fromIsMomentAuthor=false/true 正确；toId 派生=动态作者）→ **user1 回复（200）**→ **双账号未读各 1**（跨用户落库）→ user2 getMessages（COMMENT_REPLY + 中性文案「回复了你的评论」+ targetId=动态 id + fromNickName 降级）→ **读取即已读：unRead 1→0** → **E4 探针：user1 自评论后 unRead 仍=1（自评不落消息）** → user1 moment/remove → true；**重复删除幂等 true** → getMoments total=3（级联后消失）
6. **DFA 端到端**：user2 发布含黑词动态 → `{"code":400,"message":"内容包含敏感词，请修改后发布"}`（HTTP 200 + code=400，仓库既定错误口径）

联调中处理：云端 Nacos 缺 `coder-club-circle-dev.properties` 导致首启 DB 连接被拒——由用户在 namespace dev 补齐（内容对齐 practice 配置：同一 MySQL/Redis/auth 地址；`SUBJECT_SERVICE_URL` 为 practice 不消费的冗余键）后启动成功。

## 6. 已知限制与开放项（如实登记）

1. **openFinding（C1，最终审查 Critical→用户裁定治理降级）**：X1 为查询层扩展——auth 返回 VO 不含 id 字段，消费方（circle 昵称组装、practice 排行）按返回条目 userName 建键，数字标识解析仍**降级标识串**（联调 nickName="1"/"9" 即实测形态；种子数据 userName 型 created_by 正常解析）。**本 PR 不修复 practice 排行昵称显示**（任务书相关声明不成立，PR 描述已同步修正）。修复需 VO 契约增补（如 IdentifierUserItemVO 增 `id` 字段 + 消费方按 id 建键），**请求 PM 派发 B-Review 起草提案**（X1 查询层已就位，提案确认后消费侧即可生效）。
2. **治理发现（请求另案提案）**：subject/practice 的 GlobalExceptionHandler 无 NotRoleException 映射（sa-token 1.46.0 中与 NotPermissionException 为兄弟类，角色注解失败将 500）——circle 已示范同款修复，建议同步。
3. 云端 **403 未实测**（单一 admin 测试账号）；403 语义由 CircleContractTest 真实拦截链用例覆盖。
4. 敏感词 **remove→重建云端 e2e 未测**：管理端无 list 查询端点、id 不可经 API 发现（X6 范围另案）；删除重建链路由单测覆盖（`save_新词入库并重建后立即生效`）。
5. `share_message.created_by` 落 null（蓝本同款；from_id 已承载行为主体，VO 不暴露该列）——如需对齐其他表口径，随后续提案。
6. Docker 镜像构建为**结构修复**（5 个 Dockerfile pom 清单与 BOM 聚合声明 34=34 对齐；本分支 BOM 注册曾使既有 4 个 Dockerfile 间接破坏，已一并修复）；本机无 Docker，实机构建由部署环节承担。容器部署注意钉时区（`TZ=Asia/Shanghai` 或 `-Duser.timezone`，消息/评论时间格式化用系统默认时区）。
7. `start-circle.ps1` 沿用仓库 `powershell`（5.1）先例（全局规范建议 pwsh，项目约定优先，仅记录）。
8. `docs/api/coderclub-openapi.json` 头部 `info.description` 仍写「63 路径」（任务书禁止动头部）——**请求 PM 在快照同步时一并授权更新为 74**。

## 7. 后续链

1. B-Review 复核签署本回执 → PM 验收 → 快照全链同步（63→74 路径，语义差异按实际登记）→ 前端阶段三任务书（F-Impl：鸡圈页）
2. **请求 PM 派发 B-Review**：①X1 消费侧 VO 契约增补提案（openFinding ①）；②subject/practice NotRoleException 映射同步提案（开放项 ②）
3. 合入提醒：PR #15 CI 全绿，**合入由人工（用户/B-Review）在 GitHub 执行**

---
- 回执角色：后端实现（B-Impl），2026-08-30
