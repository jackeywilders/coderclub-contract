# PM 决策：本地测试账号凭据走用户级环境变量（接受）

> 角色：协调 PM
> 决策日期：2026-08-26
> 提案：`proposals/backend/2026-08-26/local-test-credential-env-proposal.md`（B-Impl 提出，PR #51 已合入 main）
> 状态：**接受（最小改动方案）**

## 1. 背景

A2 真实请求验证需登录 token（测试账号 admin）。用户指示测试账号用户名/密码列入本机用户级环境变量，后续测试直接读取。B-Impl 据此提出本提案，待 PM 核验 3 点后由用户执行。

## 2. 核验结论

| 提案核验点 | 结论 | 说明 |
| --- | --- | --- |
| 1. 变量命名 `CODER_CLUB_TEST_USERNAME` / `CODER_CLUB_TEST_PASSWORD` | **接受** | 与既有 `NACOS_USERNAME` / `NACOS_PASSWORD` 先例同风格；`CODER_CLUB_` 前缀命名空间清晰，无冲突 |
| 2. 新增 `scripts/test-env.ps1` vs 沿用 start-*.ps1 单行读取 | **按提案推荐备选：不新增脚本** | 项目已有同模式先例（start-auth.ps1 / start-subject.ps1 读 `$env:NACOS_*`），单行读取改动最小；多处复用时再评估脚本封装 |
| 3. 治理落点（是否写入后端项目 AGENTS.md/CLAUDE.md） | **建议写入，由后端实现执行** | PM 禁写后端项目；由 B-Impl 在后端项目 `AGENTS.md`/`CLAUDE.md`「本地验证凭据」章节补充约定（占位符形式，真实值不落盘）。如后端项目已有相关约定则合并 |

## 3. 执行分工

1. **用户执行**（唯一真实凭据接触点）：设置用户级环境变量
   - `CODER_CLUB_TEST_USERNAME`（如 `admin`）
   - `CODER_CLUB_TEST_PASSWORD`（真实值仅存于用户环境变量，不落盘、不提交、不回执）
2. **B-Impl 执行**（可选跟进）：后端项目 `AGENTS.md`/`CLAUDE.md` 补本地验证凭据读取约定（占位符 + 单行 `$env:` 读取模式）。
3. **后续会话读取**：验证脚本/会话直接 `$env:CODER_CLUB_TEST_*` 读取；回执与文档中账号密码一律占位符（规则 8）。

## 4. 边界确认

- 不影响运行时契约、接口、鉴权、错误码（提案 §3：不改运行时、不改 CI——CI 用自身 secrets）
- 凭据只存用户级环境变量（注册表，同用户进程可读，与 NACOS 凭据同权限语义）
- 本决策不产生契约变更，无需改 `api/` 快照与 `sync-manifest`

## 5. 关联

- 提案：`proposals/backend/2026-08-26/local-test-credential-env-proposal.md`（PR #51）
- 实施回执（真实请求验证场景来源）：`handoff/backend-to-frontend/2026-08-26/backend-a2-getSubjectPage-narrowing-report.md` §4

决策：协调 PM，2026-08-26