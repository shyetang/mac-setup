# mac-setup

🚀 **完全自动化的 macOS 开发环境初始化脚本**

一键部署全栈开发环境，支持智能配置检测与三级回滚机制。

## ✨ 特性

- ✅ **一键初始化** - 自动安装和配置整个开发环境
- ✅ **智能配置合并** - 自动识别现有 Oh My Zsh 配置，智能合并插件列表
- ✅ **完整备份恢复** - 修改前自动备份，`rollback.sh env` 可完全回滚
- ✅ **三级回滚** - soft/env/full 灵活应对各种需求
- ✅ **智能幂等** - 安全多次运行，不会重复安装或冲突

## 🎯 安装内容

| 类别 | 工具 |
|------|------|
| **系统** | Homebrew, Oh My Zsh, Starship, fzf, zoxide |
| **OMZ 插件** | zsh-syntax-highlighting（语法高亮）, zsh-autosuggestions（自动建议） |
| **语言** | Python (pyenv), Node.js (fnm), Rust (rustup), Java (jenv) |
| **软件包** | 由 `brew-packages.txt` 定义 |

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

## ⚙️ 自定义配置

编辑 `setup-macos.sh` 顶部：

```bash
# 设为 0 跳过对应语言安装
INSTALL_NODE=1
INSTALL_PYTHON=1
INSTALL_RUST=1
INSTALL_JAVA=1

# 版本策略（只锁主版本号）
PYTHON_MAJOR="3.12"   # → 3.12.x 最新
NODE_MAJOR="22"       # → 22.x 最新
JAVA_MAJOR="21"       # → 21 LTS
```

## 🔄 回滚操作

| 模式 | 命令 | 效果 |
|------|------|------|
| **soft** | `./rollback.sh soft` | 禁用配置块（不删除任何内容） |
| **env** | `./rollback.sh env` | 移除配置、删除语言环境、恢复原始设置 ✨ |
| **full** | `./rollback.sh full` | 卸载所有软件（高风险） |

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

| 文件 | 用途 |
|------|------|
| `setup-macos.sh` | 主安装脚本 |
| `rollback.sh` | 三级回滚脚本 |
| `brew-packages.txt` | 软件包配置清单 |
| `test-backup-restore.sh` | 备份恢复测试脚本 |

## 🌍 兼容性

| 系统 | 状态 |
|------|------|
| macOS Intel/Apple Silicon | ✅ 完全支持 |
| macOS Monterey+ | ✅ 推荐 |
| Ubuntu 20.04+ | ✅ 基本支持 |

## 📄 许可证

MIT License
