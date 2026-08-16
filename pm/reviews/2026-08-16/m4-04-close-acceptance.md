# M4-04 关闭验收

> **验收角色：** 协调 PM
> **验收日期：** 2026-08-16
> **任务：** M4-04 测试质量门禁
> **任务书：** `pm/requirements/2026-08-13/m4-04-test-quality-gate-task.md`
> **执行回执：** `handoff/backend-to-frontend/2026-08-16/m4-04-test-quality-gate-report.md`
> **复核签署：** 后端评审（B-Review），2026-08-16
> **验收结论：** ✅ **通过，M4-04 关闭**

## 关闭条件逐项核验

| 条件 | 要求 | 证据 | 结论 |
| --- | --- | --- | --- |
| 0 | 验收启动条件：M4-01/02/05 完成 | M4-01/02 已于 2026-08-16 本批验收通过；M4-05 同批验收通过 | ✅ |
| 1 | 覆盖率报告达基线（逐模块基线/目标/达成，达成 ≥ 目标） | 7 模块全达标（common 74.7%、auth-domain 100.0%、auth-app-controller 99.2%、subject-infra 97.8%、subject-domain 97.7%、subject-app-controller 95.3%、oss 94.8%），JaCoCo 0.8.12，行覆盖率口径 | ✅ |
| 2 | 集成测试方案文档存在（场景、命令、环境） | `docs/backend/2026-08-16-m4-04-integration-test-plan.md`（13 场景：主链路/异常链路/Trace/Feign） | ✅ |
| 3 | CI/CD 执行命令与失败处理文档存在（无外部 CI 时本地可重复 + 文档化为最小验收） | `docs/backend/2026-08-16-m4-04-cicd-commands-and-failure-handling.md`；当前无外部 CI 属可接受（任务书 §2.4 不硬性要求） | ✅ |
| 4 | 回执含原始命令输出与提交哈希，后端评审复核签署 | 实施提交 `0eac42a`、回执 `f888f98`；签署 2026-08-16（工作底稿 `designs/backend/2026-08-16/m4-04-test-quality-gate-review-workpaper.md`） | ✅ |

## 关键核验

- **覆盖率口径**：排除自动生成功样板（MapperImpl/ConverterImpl/TableDef/ConverterMapperAdapter），仅真实业务代码按行覆盖率设门槛（任务书口径 A，用户确认）。
- **补测规模**：6 模块并行补齐约 33 个新测试类（约 226 新用例），纯 JUnit5 + Mockito，外部依赖一律 mock；后端评审独立重跑全量 `mvn test` 19 模块 BUILD SUCCESS。
- **契约影响**：OpenAPI SHA-256 未变（`7576e28a…`，43/43）。

## 已知限制（验收知悉，不阻塞关闭）

1. 无外部 CI：以本地可重复命令 + 文档化为验收形式（任务书明确不硬性要求）。
2. 集成测试需真实中间件，不纳入单测覆盖率。
3. 未覆盖行多为启动/配置样板（`XxxApplication.main`、`MinioConfig`、Lombok 合成行），刻意保留。

## 备注

- 无阻塞项；任务书 §4 关闭条件 0-4 全部满足。
- 验收结论写入 `status/pm.json`（M4-04 验收通过）。
