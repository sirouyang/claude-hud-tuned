# claude-hud-tuned

[claude-hud](https://github.com/jarrodwatts/claude-hud) 的补丁集 — 在官方插件之上应用定制显示配置。非独立分支，不单独注册；`claude-hud` 的更新会保留，补丁会重新覆盖。

## 定制内容

| 设置项 | 值 |
|--------|-----|
| 语言 | 中文 (zh) |
| 布局 | 展开模式 (expanded，多行) |
| 模型格式 | 紧凑 (compact) |
| 自定义行 | `{username}`（运行时解析为当前系统用户名） |
| 上下文进度条 | 已启用 |
| Git 状态 + 文件统计 | 已启用 |
| 时长格式 | 时/分/秒 |
| 标签颜色 | 亮灰色（黑色背景下清晰可见） |

## 安装

两种方式，按需选择。

### 方式一：插件市场安装（推荐）

先安装官方 `claude-hud` 插件，再应用定制补丁。

**第一步：通过市场安装 claude-hud**

在 Claude Code 中运行：

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
```

> **Linux 用户**：如果遇到 `EXDEV: cross-device link not permitted` 错误，请运行：
> ```bash
> mkdir -p ~/.cache/tmp && TMPDIR=~/.cache/tmp claude
> ```
> 然后在该会话中重试安装命令。

**第二步：克隆本仓库并应用补丁**

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
bash apply.sh
```

`apply.sh` 会执行以下操作：
1. 查找已安装的 `claude-hud` 插件缓存
2. 用补丁文件覆盖对应文件
3. 安装状态栏包装脚本
4. 复制显示配置
5. 更新 `settings.json` 中的 statusLine 命令

**第三步：重启 Claude Code**

重启后 HUD 即会显示。

### 方式二：源码安装（不使用市场）

如果不想使用插件市场，可以直接操作源码。

**第一步：克隆仓库**

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
```

**第二步：应用补丁**

```bash
bash apply.sh
```

与方式一的第二步相同 — 需要 `claude-hud` 已安装在插件缓存中。如果尚未安装，请先在 Claude Code 中运行 `/plugin install claude-hud`，然后回来执行 `apply.sh`。

**第三步：重启 Claude Code**

### 重新安装 / 更新

`claude-hud` 插件更新后，重新运行 `apply.sh` 以应用补丁：

```bash
cd claude-hud-tuned
bash apply.sh
```

然后重启 Claude Code。

## 配置

显示配置位于 `~/.claude/plugins/claude-hud/config.json`。可直接编辑高级选项，或从本仓库重新复制：

```bash
cp plugin-config.json ~/.claude/plugins/claude-hud/config.json
```

本仓库中的关键配置文件：

| 文件 | 用途 |
|------|------|
| `plugin-config.json` | 参考配置（`apply.sh` 会复制到插件配置目录） |
| `patches/src/` | 修改后的 TypeScript 源码 |
| `patches/dist/` | 编译后的 JS 补丁 |
| `claude-hud-statusline.sh` | 状态栏包装脚本 |

## 项目结构

```
claude-hud-tuned/
  apply.sh                    # 为已安装的 claude-hud 插件打补丁
  claude-hud-statusline.sh    # 状态栏包装脚本（运行打补丁后的插件）
  plugin-config.json          # 参考配置
  patches/                    # 补丁文件
    src/                      # 修改后的 TypeScript 源码
    dist/                     # 编译后的 JS 补丁
  plugin/                     # 完整的上游 claude-hud 源码（仅供参考）
```

## 平台兼容性

| 平台 | 状态 | 备注 |
|------|------|------|
| macOS | 支持 | 需要 Node.js 18+ 或 Bun |
| Windows | 支持 | 需要 Node.js 18+（推荐使用 Git Bash 或 WSL 运行 `apply.sh`） |
| Linux | 支持 | 需要 Node.js 18+ 或 Bun；注意插件安装时 `/tmp` tmpfs 问题 |

Windows 环境下，`apply.sh` 在 Git Bash 中运行。状态栏包装脚本默认使用 `/d/nodejs/node`，如果你的 Node.js 安装在其他位置，请编辑 `claude-hud-statusline.sh`。

## 环境要求

- Claude Code v1.0.80+
- Node.js 18+（macOS/Linux 可用 Bun）
- `jq`（可选，用于自动编辑 `settings.json` — 没有时 `apply.sh` 会打印需要手动添加的 JSON 条目）

## 许可证

MIT
