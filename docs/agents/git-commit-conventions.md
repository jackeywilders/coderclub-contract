# Git 提交约定：全局剥离 AI 自动署名（Co-Authored-By）

> 生效日期：2026-08-15（Asia/Shanghai）
> 适用范围：本机所有 Git 仓库、所有提交工具（Claude Code、ZCode、Codex、手动 `git commit` 等）
> 用途：统一提交消息规范，避免 AI 工具自动追加的 `Co-Authored-By: Claude ...` 署名行进入提交历史。

## 背景

Claude Code 客户端在创建 git 提交时默认追加 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`；后续接替的 AI 工具按同一历史惯例也会追加。团队约定提交历史不再携带该自动署名，因此在 git 层统一拦截，与具体工具无关。

## 机制

- 全局钩子：`C:/Users/Sakura/.git-hooks/prepare-commit-msg`（POSIX shell 脚本，LF 行尾）
- 启用配置：`git config --global core.hooksPath C:/Users/Sakura/.git-hooks`
- 行为：git 提交落库前自动剥离提交消息中匹配以下模式的行：
  - `Co-Authored-By: Claude ...`
  - `Co-Authored-By: ... noreply@anthropic.com`
- 保留：人工手写的其他 `Co-Authored-By:` 行（如 `Alice <alice@example.com>`）不受影响。

## 验证

临时仓库实测（2026-08-15）：

- 提交消息含 `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` → 落库后仅剩标题，署名被剥离。
- 同一条消息含手写 `Co-Authored-By: Alice <alice@example.com>` → 保留，未被误删。

## 注意事项与回退

- **副作用**：全局 `core.hooksPath` 会屏蔽各仓库的 `.git/hooks/`（git 二选一）。目前各仓库无自定义项目钩子，无影响；若未来某项目需项目级钩子（如 husky），需先 `git config --global --unset core.hooksPath`，或将项目钩子并入全局目录。
- **扩展**：若未来工具追加其他 AI 署名（如其他供应商域名），在钩子脚本中补充对应匹配行。
- **回退**：`git config --global --unset core.hooksPath` 并删除 `C:/Users/Sakura/.git-hooks/prepare-commit-msg`。
- **历史提交**：此前已合入 `main` 的带署名提交保留原样，不改写历史。
