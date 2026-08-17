# S1/PR-1 前端评审复核签署（subject 解除 mock 切真实请求）

> 复核角色：前端评审（F-Review）
> 复核日期：2026-08-18
> 任务书：`pm/requirements/2026-08-18/frontend-real-api-integration-task.md`（S1）
> 实现 PR：前端仓库 `jackeywilders/CoderClubFront` **#6** `refactor(api): subject 解除 mock 切真实请求（S1/PR-1）`

## 1. 复核结论

✅ **S1 复核通过，同意合入。** 按治理流程由前端评审合入 PR #6（2026-08-17T21:20:01Z，merge commit `a855c06`）。

## 2. 规则 9 远端证据

| 字段 | 值 |
| --- | --- |
| 实施提交 SHA | `2724af4`（移除 USE_MOCK）、`c068956`（PageResult 对齐 + mock 标记废弃）、`bbfa14c`（清空 dev base URL） |
| 回执提交 SHA | 见本文件对应回执提交（交接仓库） |
| PR 号 | 前端仓库 #6 |
| R2 状态 | 已合入 `main`（`git merge-base --is-ancestor c068956 origin/main` ✓） |

## 3. 契约对照（S1 验收标准：路径/方法与契约一致）

PR `src/api/subject.ts` 13 个端点全部与契约快照 `api/coderclub-openapi.json`（43/43，SHA `9a97c055…`）匹配：

| 前端调用 | 契约 | 一致 |
| --- | --- | --- |
| GET `/subject/category/tree` | ✓ | ✅ |
| POST `/subject/category/add` | ✓ | ✅ |
| PUT `/subject/category/update` | ✓ | ✅ |
| DELETE `/subject/category/delete/{id}` | ✓ | ✅ |
| GET `/subject/label/list` | ✓ | ✅ |
| POST `/subject/label/add` | ✓ | ✅ |
| PUT `/subject/label/update` | ✓ | ✅ |
| DELETE `/subject/label/delete/{id}` | ✓ | ✅ |
| POST `/subject/getSubjectPage` | ✓ | ✅ |
| GET `/subject/querySubjectInfo/{id}` | ✓ | ✅ |
| POST `/subject/add` | ✓ | ✅ |
| PUT `/subject/update` | ✓ | ✅ |
| DELETE `/subject/remove/{id}` | ✓ | ✅ |

契约另有 5 个 subject 端点（`GET /subject/list`、`POST /subject/category/queryCategoryByPrimary`、`POST /subject/category/queryPrimaryCategory`、`POST /subject/label/queryLabelByCategoryId`、`POST /subject/querySubjectInfo`）为已定义未消费，不属于 S1 范围。

## 4. 类型对齐

- 契约 `PageResultSubjectInfo` = `pageNo, pageSize, total, totalPages, list`；PR 在 `src/types/api.d.ts` 的 `API.PageResult` 补 `totalPages: number`，与契约一致（M4-06 后列表项无装饰分页字段，外壳字段齐全）。✅

## 5. 请求链路

- `.env` `VITE_API_BASE_URL=` 清空 → dev 相对路径 → vite proxy（`/subject→localhost:3000`、`/auth→localhost:3100`、`/oss→localhost:3200`，proxy 目标与原直连端口一致，对已接真实请求的 auth/oss 无破坏）。✅
- 生产 `.env.production` `VITE_API_BASE_URL=/api` 不变，nginx 同域反代，不受影响。✅
- `request` 响应拦截器返回完整 `API.Response`（含 `data` 壳），与原 mock 分支同型，调用方解构语义不变；401 清 token 跳登录、403 提示已就位。✅

## 6. 验证证据

- 前端 `ci` workflow `check` SUCCESS（GitHub Actions run 32070073577，含 npm test / lint / api:check / build）。
- 实现提交 `bbfa14c` 说明 + PR body 实测：dev proxy 下 `POST /subject/getSubjectPage` → HTTP 401（鉴权生效，非 500）。
- R2：合入后 `src/api/subject.ts` 在 main 上 `USE_MOCK` 引用数 = 0。

## 7. Review 非阻塞观察（不阻塞 S1，转 PR-2/S2）

1. `request.get/post/…` TS 返回类型推断为 `Promise<AxiosResponse>`，运行时 resolve `API.Response`——既有模式（`src/api/index.ts` cast），PR-2 计划以 `subject.d.ts` 契约类型化收敛。
2. 视图层字段对齐（S2）未在本 PR——mock 与真实响应字段差异留给 S2 处理，符合任务书切分。
3. `subject-mock.ts` 已标 DEPRECATED 保留，供既有测试依赖；PR-2 评估清理。

## 8. 待办

- S2/S3 完成后，按任务书 S4 落 `handoff/frontend-to-backend/2026-08-18/` 双轨回执（含 `*-summary.json`：服务地址、已验证接口清单、失败请求/响应、复现条件），供 PM 验收 Gate 3 事项 4。

## 9. 版本记录

- 2026-08-18：创建（S1/PR-1 前端评审复核签署）。