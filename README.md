# mac-setup

🚀 **完全自动化的 macOS 开发环境初始化脚本**

> **设计初衷**：源于一次从 macOS 15 降级重装的经历。旨在为 **"重装系统"**、**"新机开荒"** 或 **"灾难恢复"** 场景提供一键式解决方案，让你在喝杯咖啡的时间内，将一台白板 Mac 恢复成熟悉的生产力工具。

一键部署全栈开发环境，支持智能配置检测，并通过清单文件批量管理常用软件。

**中文文档** | [English](README_EN.md)

## ✨ 特性

- ✅ **一键初始化** - 自动安装和配置整个开发环境（Node, Python, Rust, Go, Java）
- ✅ **清单式管理** - 通过 `brew-packages.txt` 声明式管理所有 CLI 和 GUI 软件，迁移只需带走一个文件
- ✅ **智能配置合并** - 自动识别现有 Oh My Zsh 配置，智能合并插件列表，不破坏原有设置
- ✅ **完整备份恢复** - 修改前自动备份，`rollback` 可完全回滚，即使试错也有安全感
- ✅ **智能幂等** - 安全多次运行，不会重复安装或冲突
- ✅ **双版本脚本** - 提供 Shell 和 Python 两种实现，满足不同需求

## 🎯 安装内容

| 类别         | 工具                                                                 |
| ------------ | -------------------------------------------------------------------- |
| **系统**     | Homebrew, Oh My Zsh, Starship, fzf, zoxide                           |
| **OMZ 插件** | zsh-syntax-highlighting（语法高亮）, zsh-autosuggestions（自动建议） |
| **语言**     | Python, Node.js, Java (Mise), Rust (rustup), Go (Homebrew)           |
| **软件包**   | 由 `brew-packages.txt` 定义                                          |

## 🚀 快速开始

### 方式一：Python 脚本（推荐）

```bash
git clone <repo-url> mac-setup && cd mac-setup

# 执行安装
python3 mac-setup.py

# 或使用参数跳过确认
python3 mac-setup.py --yes
```

### 方式二：Shell 脚本

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

### 验证环境

```bash
exec zsh  # 重载终端
python --version && node --version && rustc --version && go version
```

## 📦 脚本对比

| 特性         | `mac-setup.py` | `setup-macos.sh` |
| ------------ | -------------- | ---------------- |
| 版本管理器   | **Mise**       | pyenv/fnm/jenv   |
| Rust 安装    | **rustup**     | rustup           |
| Go 安装      | **Homebrew**   | Homebrew         |
| 命令行参数   | ✅ `--yes` 等  | ❌               |
| 配置外部化   | ✅             | ✅               |
| 智能配置合并 | ✅ OOP 实现    | ✅ awk 实现      |

> 💡 **推荐使用 `mac-setup.py`**：Mise 是现代化的一体化版本管理器，替代 pyenv/fnm/jenv

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

> 💡 完整的可选软件清单请查看 `supplementary-application.txt`

## ⚙️ 自定义配置

### Python 脚本 (`mac-setup.py`)

编辑脚本顶部的配置：

```python
# Mise 管理的语言版本
MISE_VERSIONS = {
    "python": "3.12",
    "node": "22",
    "java": "temurin-21",
}

# Go 和 Rust 使用官方推荐的工具管理
# - Go: Homebrew 直接安装
# - Rust: rustup 官方工具
```

### 命令行参数

```bash
python3 mac-setup.py --help

# 可用参数：
#   --yes, -y       跳过确认提示
#   --no-starship   不使用 Starship 主题
#   --dry-run       仅模拟运行
```

## 🔄 回滚操作

### Python 回滚脚本（推荐配合 `mac-setup.py` 使用）

```bash
python3 rollback.py --mode soft   # 禁用配置块
python3 rollback.py --mode env    # 删除环境目录 ✨
python3 rollback.py --mode full   # 完全回滚（高风险）
```

### Shell 回滚脚本（配合 `setup-macos.sh` 使用）

```bash
./rollback.sh soft   # 禁用配置块
./rollback.sh env    # 删除环境目录
./rollback.sh full   # 完全回滚
```

| 模式     | 效果                                    |
| -------- | --------------------------------------- |
| **soft** | 禁用配置块（不删除任何内容）            |
| **env**  | 移除配置、删除语言环境、恢复原始设置 ✨ |
| **full** | 卸载所有软件（高风险）                  |

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

### .zshrc 配置混乱

```bash
# 查看备份
ls -la ~/.mac-setup-backup/

# 恢复备份
cp ~/.mac-setup-backup/original-.zshrc.latest ~/.zshrc

# 或执行回滚
python3 rollback.py --mode env
```

## 📁 文件说明

| 文件                            | 用途                        |
| ------------------------------- | --------------------------- |
| `mac-setup.py`                  | **Python 安装脚本（推荐）** |
| `rollback.py`                   | **Python 回滚脚本**         |
| `setup-macos.sh`                | Shell 安装脚本              |
| `rollback.sh`                   | Shell 回滚脚本              |
| `brew-packages.txt`             | 软件包配置清单              |
| `supplementary-application.txt` | 可选/建议软件清单           |

## 🌍 兼容性

| 系统                        | 状态      | 备注                  |
| --------------------------- | --------- | --------------------- |
| macOS 14 Sonoma             | ✅ 已测试 | 开发和测试环境        |
| macOS (Intel/Apple Silicon) | ✅ 应支持 | Homebrew 路径自动适配 |
| macOS 12 Monterey+          | ✅ 应支持 | 依赖工具版本兼容      |

## 📄 许可证

MIT License
