# mac-setup

🚀 **完全自动化的 macOS 开发环境初始化脚本**

> **设计初衷**：源于一次从 macOS 15 降级重装的经历。旨在为 **“重装系统”**、**“新机开荒”** 或 **“灾难恢复”** 场景提供一键式解决方案，让你在喝杯咖啡的时间内，将一台白板 Mac 恢复成熟悉的生产力工具。

一键部署全栈开发环境，支持智能配置检测，并通过清单文件批量管理常用软件。

**中文文档** | [English](README_EN.md)

## ✨ 特性

- ✅ **一键初始化** - 自动安装和配置整个开发环境（Node, Python, Rust, Go, Java）
- ✅ **清单式管理** - 通过 `brew-packages.txt` 声明式管理所有 CLI 和 GUI 软件，迁移只需带走一个文件
- ✅ **智能配置合并** - 自动识别现有 Oh My Zsh 配置，智能合并插件列表，不破坏原有设置
- ✅ **完整备份恢复** - 修改前自动备份，`rollback.sh env` 可完全回滚，即使试错也有安全感
- ✅ **智能幂等** - 安全多次运行，不会重复安装或冲突

## 🎯 安装内容

| 类别         | 工具                                                                     |
| ------------ | ------------------------------------------------------------------------ |
| **系统**     | Homebrew, Oh My Zsh, Starship, fzf, zoxide                               |
| **OMZ 插件** | zsh-syntax-highlighting（语法高亮）, zsh-autosuggestions（自动建议）     |
| **语言**     | Python (pyenv), Node.js (fnm), Rust (rustup), Java (jenv), Go (Homebrew) |
| **软件包**   | 由 `brew-packages.txt` 定义                                              |

## 🚀 快速开始

### 1. 克隆并配置

```bash
git clone <repo-url> mac-setup && cd mac-setup

# 查看/编辑软件列表
cat brew-packages.txt
vim brew-packages.txt  # 可选：自定义
```

### 2. 执行安装

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

### 3. 验证环境

```bash
exec zsh  # 重载终端
python --version && node --version && java -version
```

## 📦 brew-packages.txt 格式

```bash
# ===== Formulae (CLI 工具) =====
git
ripgrep
fzf

# ===== Casks (GUI 应用) =====
visual-studio-code
google-chrome
```

**规则：**

- `# ===== Formulae` 标记 CLI 工具，`# ===== Casks` 标记 GUI 应用
- 每行一个包名，以 `#` 开头的其他行为注释
- **文件末尾必须有换行符**

### 默认软件清单

#### CLI 工具 (Formulae)

| 软件         | 说明                             |
| ------------ | -------------------------------- |
| `git`        | 版本控制系统                     |
| `wget`       | 文件下载工具                     |
| `ripgrep`    | 快速文本搜索（比 grep 快 10 倍） |
| `fd`         | 现代化文件查找（替代 find）      |
| `fzf`        | 模糊搜索工具（Ctrl+R 历史搜索）  |
| `jq`         | JSON 处理工具                    |
| `bat`        | 带语法高亮的 cat 替代品          |
| `htop`       | 交互式进程查看器                 |
| `zoxide`     | 智能目录跳转（替代 cd）          |
| `cmake`      | 跨平台编译工具                   |
| `pkg-config` | 编译依赖库定位                   |
| `starship`   | 现代化命令行提示符               |

#### GUI 应用 (Casks)

| 软件                 | 说明                           |
| -------------------- | ------------------------------ |
| `keka`               | 压缩/解压工具                  |
| `drawio`             | 流程图绘制工具                 |
| `iina`               | 现代化视频播放器               |
| `baidunetdisk`       | 百度网盘客户端                 |
| `appcleaner`         | 应用彻底卸载工具               |
| `warp`               | 现代化终端（Rust 编写）        |
| `raycast`            | 快捷启动器（Spotlight 替代）   |
| `openinterminal`     | Finder 右键打开终端            |
| `devtoys`            | 开发者工具集（编码/格式化）    |
| `popclip`            | 选中文本快捷操作               |
| `google-chrome`      | Chrome 浏览器                  |
| `buzz`               | 本地音频转文字（基于 Whisper） |
| `betterdisplay`      | 显示器管理工具                 |
| `aldente`            | 电池健康管理（限制充电）       |
| `visual-studio-code` | VS Code 编辑器                 |
| `zed`                | 高性能代码编辑器（Rust 编写）  |
| `iterm2`             | 增强型终端模拟器               |

> 💡 根据需要在 `brew-packages.txt` 中添加或删除软件

### 可选/建议软件

以下是一些推荐的开发工具，按需添加到 `brew-packages.txt`：

#### AI 编辑器 & 编程助手

| 软件          | 类型 | 说明                                                        |
| ------------- | ---- | ----------------------------------------------------------- |
| `cursor`      | Cask | AI 代码编辑器（VS Code fork）                               |
| `windsurf`    | Cask | Codeium AI IDE                                              |
| `trae`        | Cask | 字节跳动 AI IDE                                             |
| `antigravity` | Cask | Google DeepMind AI 编程助手                                 |
| `claude-code` | npm  | Claude CLI 编程助手（`npm i -g @anthropic-ai/claude-code`） |

#### 容器 & 虚拟化

| 软件             | 类型 | 说明                         |
| ---------------- | ---- | ---------------------------- |
| `orbstack`       | Cask | 轻量 Docker 替代（性能更好） |
| `docker`         | Cask | Docker Desktop               |
| `podman-desktop` | Cask | Podman 容器管理              |

#### 开发工具

| 软件      | 类型     | 说明               |
| --------- | -------- | ------------------ |
| `lazygit` | Formulae | Git 终端 UI        |
| `gh`      | Formulae | GitHub CLI         |
| `neovim`  | Formulae | 现代化 Vim         |
| `tmux`    | Formulae | 终端复用器         |
| `httpie`  | Formulae | 现代化 HTTP 客户端 |
| `postman` | Cask     | API 测试工具       |

#### 效率工具

| 软件        | 类型 | 说明                 |
| ----------- | ---- | -------------------- |
| `arc`       | Cask | 现代化浏览器         |
| `notion`    | Cask | 笔记 & 协作工具      |
| `obsidian`  | Cask | Markdown 知识库      |
| `1password` | Cask | 密码管理器           |
| `shottr`    | Cask | 截图工具（支持 OCR） |
| `rectangle` | Cask | 窗口管理工具         |

> 💡 完整的可选软件清单请查看 `supplementary-application.txt`

## ⚙️ 自定义配置

编辑 `setup-macos.sh` 顶部：

```bash
# 设为 0 跳过对应语言安装
INSTALL_NODE=1
INSTALL_PYTHON=1
INSTALL_RUST=1
INSTALL_JAVA=1
INSTALL_GO=1

# 版本策略（只锁主版本号）
PYTHON_MAJOR="3.12"   # → 3.12.x 最新
NODE_MAJOR="22"       # → 22.x 最新
JAVA_MAJOR="21"       # → 21 LTS
# Go 使用 Homebrew 管理，始终安装最新版
```

## 🔄 回滚操作

| 模式     | 命令                 | 效果                                    |
| -------- | -------------------- | --------------------------------------- |
| **soft** | `./rollback.sh soft` | 禁用配置块（不删除任何内容）            |
| **env**  | `./rollback.sh env`  | 移除配置、删除语言环境、恢复原始设置 ✨ |
| **full** | `./rollback.sh full` | 卸载所有软件（高风险）                  |

> 💡 **推荐使用 env 模式**：完全恢复到运行脚本前的状态

## 🔧 故障排查

### Homebrew 安装失败

```bash
# 检查网络
ping -c 3 github.com

# 手动安装
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon 添加 PATH
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
```

### Python/Node 版本未找到

```bash
# 更新版本列表，检查可用版本
pyenv install -l | grep "^  3.12"
fnm list-remote | grep "^v22"

# 修改 setup-macos.sh 中的版本号
```

### .zshrc 配置混乱

```bash
# 查看备份
ls -la ~/.mac-setup-backup/

# 恢复备份
cp ~/.mac-setup-backup/zshrc.before-*.bak ~/.zshrc

# 或执行回滚
./rollback.sh env
```

### 权限不足

```bash
chmod +x setup-macos.sh rollback.sh
```

## 📁 文件说明

| 文件                            | 用途              |
| ------------------------------- | ----------------- |
| `setup-macos.sh`                | 主安装脚本        |
| `rollback.sh`                   | 三级回滚脚本      |
| `brew-packages.txt`             | 软件包配置清单    |
| `supplementary-application.txt` | 可选/建议软件清单 |
| `test-backup-restore.sh`        | 备份恢复测试脚本  |

## 🌍 兼容性

| 系统                        | 状态      | 备注                  |
| --------------------------- | --------- | --------------------- |
| macOS 14 Sonoma             | ✅ 已测试 | 开发和测试环境        |
| macOS (Intel/Apple Silicon) | ✅ 应支持 | Homebrew 路径自动适配 |
| macOS 12 Monterey+          | ✅ 应支持 | 依赖工具版本兼容      |

## 📄 许可证

MIT License
