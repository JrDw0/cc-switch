# 本地开发记录

本文件记录本仓库的本地定制修改以及日常同步上游的 workflow。

---

## 分支说明

| 分支                | 用途                                                 |
|---------------------|------------------------------------------------------|
| `main`              | 纯净同步上游（upstream），**不要在此分支做本地修改** |
| `local/otty-terminal` | 本地 Otty 终端支持修改，基于 main + 本地提交       |

---

## 本地修改内容

### `local/otty-terminal` 分支

- 为 macOS 添加 **Otty.app** 终端支持
- 支持设置 → 首选终端 → 选择 Otty
- 实现位置：
  - `src-tauri/src/session_manager/terminal/mod.rs`
  - `src-tauri/src/commands/misc.rs`
  - `src/components/settings/TerminalSettings.tsx`
- Otty 位置：`/System/Volumes/Data/Applications/Otty.app`
- 使用 AppleScript `do script` 接口（与 Terminal.app 风格一致）

---

## 日常同步上游（定期执行，例如每周）

```bash
# 1) 同步 upstream 到本地 main
git checkout main
git fetch upstream
git merge upstream/main --ff-only
git push origin main

# 2) 将最新上游合并到本地 feature 分支（rebase 保持历史干净）
git checkout local/otty-terminal
git rebase main
# 若遇冲突：编辑 → git add <file> → git rebase --continue
```

---

## 打包替换本地 App

```bash
# 在 local/otty-terminal 分支上
git checkout local/otty-terminal
pnpm tauri build

# 产物位置：
# src-tauri/target/release/bundle/macos/CC Switch_xxx.dmg（或 .app）
```

打包完成后把 `.app` 拖到 `/Applications` 替换即可。

---

## 新增本地修改

在 feature 分支上开发：

```bash
git checkout local/otty-terminal
# ... 编辑文件 ...
git add -A
git commit -m "feat(xxx): description"
```

如需新增独立的本地功能，可新建类似前缀的分支，如 `local/xxx-another-feature`。

---

## 远程配置

| remote     | 地址                                        |
|------------|---------------------------------------------|
| `origin`   | 你的 fork（`JrDw0/cc-switch`）              |
| `upstream` | 上游原仓库（`farion1231/cc-switch`）         |
| `fork`     | 同上 fork（与 origin 同指向）               |

---

## 快速参考

```bash
# 一键同步并更新分支
git checkout main && git fetch upstream && git merge upstream/main --ff-only && \
git checkout local/otty-terminal && git rebase main

# 打包
pnpm tauri build
```
