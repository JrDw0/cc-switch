# 本地开发记录

本文件记录本仓库的本地定制修改以及日常同步上游的 workflow。

---

## 分支说明

| 分支            | 用途                                                 |
|-----------------|------------------------------------------------------|
| `main`          | 纯净同步上游（upstream），**不要在此分支做本地修改**   |
| `local/personal` | 个人长期定制主分支（原 `local/otty-terminal`，基于 main + 本地提交） |

---

## 本地修改内容

### `local/personal` 分支

当前本地独有的定制功能：

- **技能批量管理**（`SKILLS_APP_IDS` 批量选择替换）
- **会话管理页时间筛选**（时间范围过滤）
- **provider filter 默认 'all'**（列表页默认值优化）
- **dev-build.sh 本地构建脚本**（~3 分钟打包替换 `/Applications/CC Switch.app`）
- **LOCAL_DEV.md + AGENTS.md**（本文件，agent 入口文档）

> 注：原 Otty 终端支持提交已被上游原生实现（上游自带 CLI 优先 + AppleScript 回退，更完善），本分支的 Otty 提交已可废弃。

---

## 日常同步上游（merge 方式，推荐）

**注意：本次调整将 rebase 改为 merge。**

对长期维护的 fork 来说，rebase 会让每个本地提交都被重写，冲突反复出现，且已推送后需 `--force-with-lease` 强推；merge 则保留清晰离线历史，冲突只解一次，更安全。

```bash
# 1) 同步 upstream 到本地 main（快进）
git checkout main
git fetch upstream
git merge upstream/main --ff-only
git push origin main

# 2) 将最新上游合并到工作分支（merge，不 rebase）
git checkout local/personal
git merge main
# 若遇冲突：编辑 → git add <file> → git commit
```

> 曾用 rebase 时可能出现本地 main 严重落后。只需上面第 1) 步的
> `git merge upstream/main --ff-only` 就能把 main 追平，无需重写定制分支历史。

---

## 打包替换本地 App

### 方式 A：快速本地开发测试（推荐）

```bash
./scripts/dev-build.sh
```

这个脚本使用 Tauri 的 `debug` profile，只生成 `.app`，不生成 DMG 或 updater 文件。它会完整替换 `/Applications/CC Switch.app`，包含构建前端 + 编译 Rust + 替换 + 启动的完整流程。

**耗时**：~3 分钟（Rust 增量编译）

> ⚠️ **签名错误可忽略**：构建末尾可能出现 `TAURI_SIGNING_PRIVATE_KEY` 报错，这是 updater 签名私钥未配置导致的。本地测试不需要签名，App Bundle 仍会正常生成。

**脚本自动做的事**：
1. `pnpm tauri build --debug --bundles app`（自动包含前端构建）
2. 关闭正在运行的 CC Switch
3. 替换 `/Applications/CC Switch.app`
4. 移除 quarantine 标记
5. 启动应用

### 方式 B：Release 完整打包（正式发布）

```bash
pnpm tauri build
```

**耗时**：~6 分钟

# 产物位置：
- `src-tauri/target/release/bundle/macos/CC Switch.app`
- `src-tauri/target/release/bundle/dmg/CC Switch_3.19.0_aarch64.dmg`

### ⚠️ 不要用 cargo build 直接编译

Tauri v2 将前端资源（`dist/`）在编译时嵌入 Rust 二进制。直接运行 `cargo build` 时，build script 的 `rerun-if-changed` 只监控 `tauri.conf.json` 和 `capabilities/`，不监控 `dist/`。前端更新后直接 `cargo build` 会导致**白屏**（嵌入旧前端资源）。如果一定要用增量编译，必须在前端构建后 `touch src-tauri/tauri.conf.json` 强制 build script 重新执行。

| 方式 | 用途 | 耗时 |
|---|---|---|
| `./scripts/dev-build.sh` | 本地安装测试 | ~3 分钟 |
| `pnpm tauri build` | 正式发布 | ~6 分钟 |
| `pnpm tauri dev` | 开发调试 | 热更新，不替换安装包 |

---

## 新增本地修改

在 feature 分支上开发：

```bash
git checkout local/personal
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

> 之前有一个 `fork` remote 与 `origin` 同指向 fork，属冗余，已移除。统一用 `origin` 表示自己的 fork。

---

## 快速参考

```bash
# 一键同步并更新分支
git checkout main && git fetch upstream && git merge upstream/main --ff-only && \
git push origin main && git checkout local/personal && git merge main

# 快速本地安装测试
./scripts/dev-build.sh

# 完整打包（首次或依赖变更后）
pnpm tauri build
```
