# claude-hud-tuned

> [English](README.md)

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

### 方式一：插件市场安装（推荐）

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

**第三步：重启 Claude Code**

### 方式二：源码安装

```bash
git clone https://github.com/user/claude-hud-tuned.git
cd claude-hud-tuned
bash apply.sh
```

需要 `claude-hud` 已安装在插件缓存中。如果尚未安装，请先在 Claude Code 中运行 `/plugin install claude-hud`，然后执行 `apply.sh`。

### 重新安装 / 更新

`claude-hud` 插件更新后，重新运行 `apply.sh` 并重启 Claude Code：

```bash
cd claude-hud-tuned
bash apply.sh
```

## 配置

显示配置位于 `~/.claude/plugins/claude-hud/config.json`。可直接编辑，或从本仓库重新复制：

```bash
cp plugin-config.json ~/.claude/plugins/claude-hud/config.json
```

## 项目结构

```
claude-hud-tuned/
  apply.sh                    # 为已安装的 claude-hud 插件打补丁
  claude-hud-statusline.sh    # 状态栏包装脚本（自动检测 node）
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

状态栏包装脚本会自动从 PATH 中检测 `node`。如果未找到，会检查常见安装路径（`/usr/local/bin/node`、nvm 路径等）。Node.js 缺失时会显示明确的错误提示。

## 环境要求

- Claude Code v1.0.80+
- Node.js 18+（macOS/Linux 可用 Bun）
- `jq`（可选，用于自动编辑 `settings.json` — 没有时 `apply.sh` 会打印需要手动添加的 JSON 条目）

## 许可证

MIT
