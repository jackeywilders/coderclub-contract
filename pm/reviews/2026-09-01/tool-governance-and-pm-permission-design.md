# 工具治理与 PM 权限扩展设计（2026-09-01）

> 角色：协调 PM
> 日期：2026-09-01
> 流程：grill-me（工具替代验证 + 范围/方案/边界逐层确认）+ brainstorming（方案 B：全局权威 + 各仓速查；方案 X：全局内联自包含）
> 状态：已批准，待实施

## 1. 背景与验证结论

### 1.1 Git Bash 替代 PowerShell 验证（2026-09-01 实测）

`D:\Program Files\Git\bin\bash.exe`（bash 5.3.15，Git for Windows）在大部分场景可替代 PowerShell：

| 维度 | 结果 |
| --- | --- |
| 核心 unix 工具（ls/grep/sed/awk/find/curl/git/node/npm/mvn） | ✅ 全部可用 |
| 中文编码（UTF-8 读写/grep/文件名/git log） | ✅ 正常 |
| git 操作（status/log/fetch/push） | ✅ 正常 |
| 路径风格（/g/ 挂载） | ✅ 正常 |
| 管道/组合 | ✅ 正常 |

**不能替代的边界**：运行项目自带 `.ps1` 启动脚本（`start-*.ps1` 含 Nacos 环境变量预配置）、Windows 系统级操作（注册表/服务/环境变量持久化/UAC）。

### 1.2 关键根因：裸 `bash` 被 WSL 劫持

- `C:\windows\system32\bash.exe` = **WSL 启动器**（本机已装 Ubuntu-24.04），`bash` 裸名解析到它而非 Git Bash
- `D:\Program Files\Git\bin` **不在 PATH**（PATH 只有 `Git\cmd`，且 `Git\cmd` 无 bash.exe）
- 治理文件此前写「用 Git Bash」但 agent 按裸 `bash` 调不到 → 退化 pwsh（写了但没落地的根因）
- **处置**：治理文件强制用**绝对路径** `D:\Program Files\Git\bin\bash.exe -lc`，**禁止裸 `bash`**；不依赖 PATH 修改（避免 Git\usr\bin 与 system32 的 find/sort 同名冲突）

### 1.3 jq 已装（scoop）

- 经 scoop 安装 jq 1.8.2（main bucket，官方 jqlang 源），装到 `G:\packages\scoop\user\apps\jq`，shim 在 `G:\packages\scoop\user\shims`（已在用户 PATH）
- Git Bash 内 `jq` 直接可用（实测）；兜底 `python3 -c "import json;..."`（Python 3.14.7 已装）

## 2. 设计：工具选择决策表（内联到全局 AGENTS）

| 场景 | 默认工具 | 说明 |
| --- | --- | --- |
| git 操作 / 文件搜索 / 文本处理 | **Git Bash** | `D:\Program Files\Git\bin\bash.exe -lc "..."`，纯文本稳定输出 |
| JSON 处理 | **jq**（已装） | Git Bash 内直接 `jq`；无 jq 时 `python3 -c "import json;..."` 兜底 |
| 构建（mvn/npm） | Git Bash 优先 | 输出稳定；CI 亦为 bash |
| 运行 `.ps1` 启动脚本 | **pwsh** | 内含 Nacos 环境变量预配置 |
| Windows 系统级 | **pwsh** | 注册表/服务/环境变量持久化/UAC |
| Git Bash 调用 | **绝对路径 + `-lc`** | **禁止裸 `bash`**（被 WSL 启动器劫持） |

## 3. 设计：全局 AGENTS 内联（方案 X，自包含）

- 全局 `AGENT.md` 第 5 条：从【建议】升级为【必须】+ 绝对路径 + 禁止裸 bash + jq 说明
- **决策表直接内联**（不建附表），保证单文件自包含、跨 agent 工具可移植
- 全局 MD **不挂钩任何项目级内容**（角色权限属项目级，不写全局）

## 4. 设计：三仓库改动（方案 B，全局权威 + 各仓速查）

| 文件 | 改动 |
| --- | --- |
| 交接仓库 `AGENTS.md` | ① 协作规则补「工具选择」条（规则 10）；② 协调 PM「允许写入」节扩展（三仓治理文件） |
| 后端 `CoderClub/CLAUDE.md` | 加「工具约定」小节（Git Bash 绝对路径 / pwsh 用于 .ps1 与系统级 / jq） |
| 前端 `CoderClubFront/CLAUDE.md` | 加「工具约定」小节（Git Bash 绝对路径 / jq / pwsh 系统级） |
| 后端/前端 `AGENTS.md` | 不加（CLAUDE 已覆盖，YAGNI） |

## 5. 设计：PM 治理文件权限扩展（项目级）

**协调 PM「允许写入」扩展**（写入交接仓库 AGENTS.md 协调 PM 节）：

- **允许**：三大仓库（交接/后端/前端）的治理文件——`AGENTS.md`、`CLAUDE.md`、`CONTEXT.md`（治理节）、`docs/agents/**`、`docs/INDEX.md`
- **不允许**：项目内容文件——`README.md`、`DEPLOYMENT.md`、`docs/database/**`、`docs/api/coderclub-openapi.json`（运行时契约）、`docs/superpowers/**`（实现层技能产物）、源码/业务配置
- **例外**：`CONTEXT.md` 的架构/技术内容不改（PM 仅治理节；架构描述归实现层）
- **仅项目级**：此权限写入交接仓库 AGENTS，全局 AGENTS 不挂钩

## 6. 合入方式

- 交接仓库改动：经 `pm` 分支 PR（自动合入）
- 后端/前端 CLAUDE.md：经各自 `docs/governance-*` 分支 PR（私有仓，用户手动合入）
- 全局 AGENTS（`G:\Dev\agent\agens rules\AGENT.md`）：本机文件，直接修改（不属任何 git 仓库）

## 7. 版本记录

- 2026-09-01：创建（grill-me 验证 + brainstorming 设计定案）。
