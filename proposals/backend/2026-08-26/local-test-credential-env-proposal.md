# 提案：本地测试账号凭据走用户级环境变量（最小改动方案）

> **提案角色：** 后端实现（B-Impl）
> **提案日期：** 2026-08-26
> **背景：** A2 真实请求验证需登录 token，本会话向用户索取测试账号（admin）。用户指示：将测试账号用户名/密码列入本机用户级环境变量，后续测试直接读取使用；本提案供协调 PM 核验，确认可行后由用户执行。
> **类型：** 本地开发/验证流程约定（不影响运行时契约、不涉及接口/鉴权/错误码变更）

## 1. 现状与痛点

- 每次本地/云端真实验证需登录 token → 需要测试账号凭据；目前凭据仅在会话中口头传递，无统一读取机制
- 已有先例：`start-auth.ps1` / `start-subject.ps1` 通过用户级环境变量 `NACOS_USERNAME` / `NACOS_PASSWORD` 读取 Nacos 凭据并注入子进程——**测试账号凭据可完全复用此模式**，改动最小

## 2. 方案（最小改动）

### 2.1 环境变量约定（用户执行）

| 变量名 | 值 | 说明 |
| --- | --- | --- |
| `CODER_CLUB_TEST_USERNAME` | `admin`（示例，脱敏） | 测试账号用户名 |
| `CODER_CLUB_TEST_PASSWORD` | `<password>` | 测试账号密码 |

- 用户级（User scope）环境变量，**不写入项目文件/提交/回执/日志**（延续规则 8：真实凭据不落盘）
- 若凭据轮换，仅更新环境变量，无需改代码/脚本

### 2.2 读取脚本（可选，后端项目内新增 1 个小脚本）

新增 `scripts/test-env.ps1`（或 `tools/` 下），职责：
- 检查 `CODER_CLUB_TEST_USERNAME` / `CODER_CLUB_TEST_PASSWORD` 是否设置，缺失时报错提示设置
- 输出遮蔽后的就绪状态（只报长度/是否设置，不打明文）
- 提供可被验证脚本 `Import-Module` 或点源的简单函数（如 `Get-CoderClubTestCredential` 返回 `PSCustomObject{UserName; Password}`，仅内存传递）

> 备选（改动更小）：不新增脚本，仅在会话约定 + 各验证脚本里直接读 `$env:CODER_CLUB_TEST_*`（与 start-*.ps1 读取 NACOS 同款单行）。**推荐备选**，因项目已有同模式先例；脚本方案仅在需要多处复用时引入。

### 2.3 验证脚本（使用方，按需）

真实验证场景（如 A2 §2.6 类型）的命令封装示例（不落盘）：

```powershell
$user = $env:CODER_CLUB_TEST_USERNAME
$pass = $env:CODER_CLUB_TEST_PASSWORD
# 登录 -> token -> 调 getSubjectPage（凭据仅在进程内存）
```

## 3. 边界与影响

- **不改运行时**：仅本地/云端验证流程约定，不涉及接口、鉴权、错误码、契约
- **不改 CI**：CI 用自身 secrets，不受本约定影响（本约定仅本机开发验证）
- **不落盘**：凭据只存在于用户级环境变量（注册表，同用户进程可读——与 NACOS 凭据同权限语义）；不进项目文件、提交、回执、日志
- **脱敏**：任何回执/文档中账号密码以占位符呈现（规则 8）

## 4. 待 PM 核验点

1. 变量命名是否合适（`CODER_CLUB_TEST_USERNAME` / `CODER_CLUB_TEST_PASSWORD`；或 PM 有统一 naming 约定）
2. 是否需要新增 `scripts/test-env.ps1`（复用脚本），还是沿用 start-*.ps1 的单行读取（最小）
3. 是否需要把约定写入后端项目 `AGENTS.md`/`CLAUDE.md`（本地验证凭据章节）——由 PM 决定治理落点

## 5. 流程

- 本提案经 `claude/backend-proposals` PR 合入交接仓库 main（governance-check 自动合并），待 PM 核验
- PM 确认后由**用户**设置环境变量（`setx CODER_CLUB_TEST_USERNAME admin` 等，或 GUI 环境变量面板）；后续会话直接读取

- 提案角色：后端实现（B-Impl）
- 日期：2026-08-26