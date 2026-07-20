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

### 方式 A：完整打包（首次或依赖变更时）

```bash
git checkout local/otty-terminal
pnpm tauri build

# 产物位置：
# src-tauri/target/release/bundle/macos/CC Switch.app
# src-tauri/target/release/bundle/dmg/CC Switch_3.17.0_aarch64.dmg
```

打包完成后把 `.app` 拖到 `/Applications` 替换即可。

### 方式 B：增量打包（日常改代码推荐）

```bash
./scripts/quick-build.sh
```

**原理**：跳过了 `.app`/`.dmg` 重新打包阶段，cargo 自带增量编译，只重编译改动部分。

**耗时对比**：
| 方式 | 首次 | 后续改代码 |
|---|---|---|
| `pnpm tauri build` | ~6 分钟 | 仍然要 bundle，慢 |
| `./scripts/quick-build.sh` | 不可用（需先完整打包） | **10-30 秒**，只替换二进制 |

**脚本自动做的事**：
1. 检测 `dist/` 是否过期，按需跑 `pnpm vite build`（更新前端资源）
2. `cargo build --release`（增量编译 Rust 后端，含嵌入前端资源）
3. 关闭正在运行的 CC Switch
4. 复制二进制到 `/Applications/CC Switch.app/Contents/MacOS/cc-switch`
5. 移除 quarantine 避免首次打开提示

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

# 打包（日常推荐增量脚本）
./scripts/quick-build.sh

# 完整打包（首次或依赖变更后）
pnpm tauri build
```
