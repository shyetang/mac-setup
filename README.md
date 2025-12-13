# mac-setup

🚀 **完全自动化的 macOS 环境初始化与配置脚本**

一键部署开发环境，支持安全的三级回滚机制。无需手动配置，所有操作都可追踪和撤销。

## ✨ 特性

- ✅ **一键初始化** - 自动安装和配置整个开发环境
- ✅ **三级回滚** - soft/env/full，灵活应对各种需求
- ✅ **智能幂等** - 安全多次运行，不会重复安装
- ✅ **自动备份** - 所有修改前自动备份，数据不会丢失
- ✅ **跨平台** - 兼容 macOS 和 Linux（使用兼容的 awk/bash）
- ✅ **清晰日志** - 实时反馈执行进度，问题一目了然

## 🎯 功能清单

### 系统工具
- **Homebrew** - 自动安装或更新
- **Oh My Zsh** - Shell 配置和主题
  - **插件配置** - 自动启用 git、sudo、extract、fzf、colored-man-pages 五个插件
  - **zoxide 集成** - 智能目录导航（替代 z 插件）
- **Starship** - 现代化命令行提示符（可选）
- **fzf** - 模糊查找工具补全

### 编程语言环境
| 语言 | 管理工具 | 版本策略 |
|------|---------|--------|
| **Rust** | rustup | 最新稳定版 |
| **Python** | pyenv | 3.12.x 最新 |
| **Node.js** | fnm | 22.x 最新 |
| **Java** | jenv | 21 LTS |

### 软件包管理
- 从 `brew-packages.txt` 自动解析软件列表
- 智能判断 cask（GUI）vs 普通包（CLI）
- 增量更新 Brewfile，不覆盖用户修改

### Oh My Zsh 插件详解

本脚本自动配置以下 Oh My Zsh 插件：

| 插件 | 功能 | 说明 |
|------|------|------|
| **git** | Git 别名与补全 | 提供常用 git 命令简写（如 `ga`→`git add`）|
| **sudo** | 快速加 sudo | 按两次 ESC 快速在命令前添加 `sudo` |
| **extract** | 通用解压 | `x <file>` 自动识别格式解压任何类型文件 |
| **fzf** | 模糊搜索补全 | 增强 shell 补全，ctrl-r 历史命令搜索，ctrl-t 文件选择 |
| **colored-man-pages** | 彩色 man 手册 | 为 man 页面添加语法高亮，提升可读性 |

#### zoxide 集成

脚本自动安装并集成 [zoxide](https://github.com/ajeetdsouza/zoxide)，这是一个更智能的目录导航工具：

```bash
z <path>         # 模糊匹配并跳转到历史目录
z <path> -i      # 交互式选择（使用 fzf）
zi               # 交互式选择最常访问的目录
```

**zoxide vs z 插件：**
- ❌ 脚本**不使用** OMZ 的 z 插件，以避免冲突
- ✅ 使用独立的 zoxide 工具，更聪明、更快速
- 🔗 与 fzf 完美配合，提供交互式目录选择

#### 工具协同

```
fzf (模糊查找引擎)
  ↓
OMZ fzf 插件 (增强 shell 补全)
  + zoxide (智能目录导航)
  = 强大的交互式导航体验
```

**常用组合：**
```bash
# 1. 快速跳转到历史目录
z django  # 模糊匹配包含 "django" 的历史目录

# 2. 交互式目录选择
zi        # 弹出 fzf 菜单，选择要跳转的目录

# 3. 命令历史搜索
ctrl+r    # fzf 交互式搜索历史命令

# 4. 文件路径补全
vim **<TAB>  # fzf 浏览文件树选择要编辑的文件
```

#### 自定义插件

如需修改 OMZ 插件配置，编辑 `setup-macos.sh` 的这一行：

```bash
# 第 104 行附近
plugins=(git sudo extract fzf colored-man-pages)
```

例如添加更多插件：
```bash
plugins=(git sudo extract fzf colored-man-pages autojump web-search)
```

⚠️ **重要提示：** 修改后重新运行脚本，或手动编辑 `~/.zshrc` 中的 `AUTO-SETUP-CORE` 块。

## 🚀 快速开始

### 📌 关键说明：brew-packages.txt 的重要性

**`brew-packages.txt` 是什么？**

这是脚本的**核心配置文件**，定义了将要安装的所有软件包。它相当于一个"购物清单"，告诉脚本应该为你安装哪些工具。

**工作原理：**
```
brew-packages.txt (软件列表)
        ↓
    setup-macos.sh (解析和安装)
        ↓
    Brewfile (Homebrew 配置)
        ↓
    brew bundle (统一安装)
```

**为什么重要？**
- ✅ **自定义安装** - 只装你需要的，不装多余的
- ✅ **易于维护** - 用 git 管理你的开发环境配置
- ✅ **团队协作** - 让团队成员拥有完全相同的环境
- ✅ **可追踪** - 清晰记录每个软件的用途和说明

---

### 第一步：准备工作
```bash
# 克隆仓库
git clone <repo-url> mac-setup
cd mac-setup

# 查看即将安装的软件
cat brew-packages.txt
```

### 第二步：自定义配置

#### 编辑软件包列表
```bash
vim brew-packages.txt
# 添加或移除你需要的软件
```

示例：
```bash
# ===== Formulae (CLI 工具) =====
git
wget
ripgrep
fd
fzf
jq
bat
htop
zoxide
cmake
pkg-config
starship

# ===== Casks (GUI 应用) =====
keka
drawio
iina
warp
raycast
google-chrome
devtoys
aldente
visual-studio-code
zed
```

**格式说明：**
- **必须使用规范的分类标记：**
  - `# ===== Formulae (CLI 工具) =====` - 命令行工具
  - `# ===== Casks (GUI 应用) =====` - 图形界面应用
- 每行一个包名（必须是 Homebrew 可识别的名称）
- 分类标记下方的所有包会被归入该分类
- 以 `#` 开头的其他行为普通注释（自动跳过）
- 空行自动跳过
- **不支持行内注释**，注释必须单独成行
- **文件末尾必须有换行符**（否则最后一行无法被读取）

#### 自定义编程语言版本（可选）
编辑 `setup-macos.sh` 第 7-17 行的配置：

```bash
# ⭐ 用户可配置区（最重要）
INSTALL_NODE=1       # 设为 0 跳过 Node.js 安装
INSTALL_PYTHON=1     # 设为 0 跳过 Python 安装
INSTALL_RUST=1       # 设为 0 跳过 Rust 安装
INSTALL_JAVA=1       # 设为 0 跳过 Java 安装

# ---- 语言版本策略（只锁大版本）----
PYTHON_MAJOR="3.12"  # → 安装 3.12.x 最新
NODE_MAJOR="22"      # → 安装 22.x 最新
JAVA_MAJOR="21"      # → 安装 21.x 最新（LTS）
```

### 第三步：执行初始化
```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

**执行过程：**
1. 脚本列出所有待执行操作
2. 显示将要安装的编程语言和软件
3. 等待用户确认（输入 `y` 继续）
4. 自动安装并配置所有环境
5. 完成后提示后续验证步骤

### 第四步：验证环境
```bash
# 重新打开终端或运行
exec zsh

# 验证所有工具已安装
python --version   # Python 3.12.x
node --version     # v22.x.x
rustc --version    # rustc x.x.x
java -version      # openjdk 21.x.x
brew --version     # Homebrew x.x.x
```

## 🔄 回滚操作

脚本对所有修改都使用特殊标记，支持精确回滚：

```bash
### AUTO-SETUP-CORE ###
...配置内容...
### END AUTO-SETUP-CORE ###
```

### soft 模式 - 禁用所有配置（最安全）
```bash
./rollback.sh soft
```

**效果：**
- ✅ 禁用所有 AUTO- 配置块
- ✅ **不删除任何内容**
- ✅ 保留所有已安装软件
- ✅ 环境变量失效但数据完整

**适用场景：** 临时禁用脚本配置，测试原生环境

---

### env 模式 - 恢复用户环境（推荐）
```bash
./rollback.sh env
```

**删除项目：**
- `.oh-my-zsh` - Shell 框架
- `.cargo` - Rust 工具链
- `.pyenv` - Python 版本管理
- `.fnm` - Node.js 版本管理
- `.jenv` - Java 版本管理
- `.zshrc` 中的所有 AUTO- 配置块

**保留项目：**
- ✅ Homebrew 及所有软件包
- ✅ 用户的自定义 .zshrc 配置
- ✅ 其他用户文件

**适用场景：** 卸载脚本配置，保留已安装软件

---

### full 模式 - 完全卸载（高风险）
```bash
./rollback.sh full
```

**执行步骤：**
1. 执行 env 模式的所有操作
2. 卸载 Brewfile 中安装的**所有软件**
3. 询问是否卸载 Homebrew（可选）

⚠️ **警告：** 此操作删除大量软件，建议仅在完全重置系统时使用

**适用场景：** 完全重置系统环境

---

## � 软件包详细说明

### 什么是 brew-packages.txt？

`brew-packages.txt` 是脚本的**核心配置文件**，用于定义需要安装的所有软件包。

**工作流程：**
1. 脚本读取 `brew-packages.txt`
2. 根据分类标记（`Formulae` 或 `Casks`）识别软件类型
3. 生成对应的 Homebrew Brewfile 条目
4. 使用 `brew bundle` 统一安装

**性能优化：**
- ✅ **离线友好** - 不再需要网络请求来检测软件类型
- ✅ **速度快** - 基于文件标记的解析，无需调用 `brew info`
- ✅ **可预测** - 明确的分类控制，避免自动检测的不确定性

**特点：**
- ✅ 支持注释（# 开头的行会被忽略）
- ✅ 支持空行（自动跳过）
- ✅ 增量更新（不覆盖用户现有的 Brewfile）
- ✅ 易于版本控制（用 git 追踪变化）
- ✅ 每个软件都有中文说明注释

**文件格式示例：**
```bash
# ===== Formulae (CLI 工具) =====
git
wget
ripgrep

# ===== Casks (GUI 应用) =====
keka
drawio
```

⚠️ **重要：** 分类标记必须包含关键词 `Formulae` 或 `Casks`，脚本通过正则表达式识别这些标记。

---

### 📋 当前安装的软件清单

> 以下清单与 `brew-packages.txt` 保持一致，分为 **Formulae (CLI 工具)** 和 **Casks (GUI 应用)** 两大类。

---

#### Formulae (CLI 工具)

| 软件名 | 功能 | 使用场景 |
|-------|------|---------|
| **git** | 版本控制系统 | 所有开发项目必备 |
| **wget** | 文件下载工具 | 从网络下载文件 |
| **ripgrep (rg)** | 快速文本搜索 | 比 grep 快 10+ 倍，用于代码搜索 |
| **fd** | 文件查找工具 | find 的现代替代品，更快更易用 |
| **fzf** | 模糊查找工具 | 增强 bash/zsh 交互，模糊搜索历史和文件 |
| **jq** | JSON 处理工具 | 命令行 JSON 查询和转换 |
| **bat** | Cat 增强版 | 语法高亮的文件查看器，替代 cat |
| **htop** | 进程监控工具 | top 的增强版，实时监控系统资源 |
| **zoxide** | 目录导航工具 | 智能目录跳转，比 cd 更聪明 |
| **cmake** | 跨平台编译工具 | C/C++ 项目构建，Xcode 开发 |
| **pkg-config** | 库文件定位工具 | 帮助编译器找到依赖库位置 |
| **starship** | 现代化命令行提示符 | 替换默认 shell 提示符，显示 git 分支、环境信息等 |

**何时需要这些工具：**
- 开发工作流中频繁使用命令行
- 需要快速搜索和查找文件
- 编译 C/C++ 项目或安装需要编译的依赖包
- 监控系统性能和处理 JSON 数据
- 美化和增强终端体验（starship、zoxide、fzf）

---

#### Casks (GUI 应用)

| 软件名 | 功能 | 使用场景 |
|-------|------|---------|
| **Keka** | 压缩/解压工具 | 处理 ZIP、RAR、7Z 等压缩文件 |
| **Draw.io** | 流程图和图表工具 | 绘制系统架构图、流程图、UML 图 |
| **IINA** | 视频播放器 | 播放各种格式视频，比系统播放器功能强大 |
| **百度网盘 (baidunetdisk)** | 云存储客户端 | 访问百度网盘文件 |
| **AppCleaner** | 应用卸载工具 | 彻底卸载应用及其相关文件 |
| **Warp** | 现代终端 | Rust 开发的高性能终端，支持 AI |
| **Raycast** | 快速启动器 | Spotlight 替代品，快速启动应用和查找文件 |
| **Open in Terminal (openinterminal)** | 右键菜单工具 | 在任意文件夹右键打开终端 |
| **DevToys** | 开发者工具集 | JSON 格式化、编码解码、时间戳转换等 |
| **PopClip** | 快捷粘贴板工具 | 选中文本自动出现快捷操作（格式化、翻译等） |
| **Google Chrome** | 网页浏览器 | 开发必备浏览器 |
| **Buzz** | 本地音频转录工具 | 将音频/视频转为文字（离线，基于 OpenAI Whisper） |
| **BetterDisplay** | 显示器管理工具 | 调节分辨率、刷新率，管理多屏 |
| **AlDente** | 电池健康管理 | 限制充电到指定百分比，延长电池寿命 |
| **Visual Studio Code** | 代码编辑器 | 轻量级但功能强大的代码编辑器，支持大量扩展 |
| **Zed** | 高性能代码编辑器 | Rust 开发的现代编辑器，启动快速、协作功能强大 |

**何时需要这些工具：**
- 日常开发工作中需要各种辅助工具
- 管理系统和维护电脑健康
- 提高工作效率

---

### 🛠️ 如何修改软件列表

#### 添加新软件
```bash
vim brew-packages.txt

# 在对应分类下添加
# 例如在 CLI 工具下添加 node-gyp
git
wget
ripgrep
fd
node-gyp       # ← 新增软件
```

#### 移除不需要的软件
```bash
# 删除行即可，或注释掉
# 例如不需要 100 disk，注释掉
# 百度网盘
```

#### 重新运行安装
```bash
# 修改后，可安全地重新运行
./setup-macos.sh

# 脚本会：
# 1. 检查已有软件（跳过已安装）
# 2. 安装新增软件
# 3. 不会卸载被注释的软件
```

---

### 🔍 查询软件是否存在

```bash
# 搜索软件
brew search package-name

# 查看软件详情
brew info package-name

# 查看 cask（GUI应用）
brew search --casks keyword
```

---

### ⚠️ GNU 工具说明

脚本默认注释了以下 GNU 工具：

```bash
# ===== GNU 工具 =====
# coreutils         # 注意：会在 PATH 中优先级前置，可能影响系统命令
# gnu-sed           # 注意：可能与 BSD sed 冲突
# gnu-tar           # 注意：可能与 BSD tar 冲突
```

**为什么默认不安装？**
- macOS 自带 BSD 版本的 sed、tar 等
- GNU 版本的这些工具会导致 PATH 优先级问题
- 可能破坏某些依赖 BSD 版本的脚本

**何时需要取消注释？**
- 有 Linux 脚本需要 GNU 工具语法
- 明确需要 GNU sed 的高级功能
- 了解 PATH 管理的开发者

**如何使用？**
```bash
# 1. 在 brew-packages.txt 中取消注释
coreutils

# 2. 重新运行
./setup-macos.sh

# 3. GNU 工具会以 g 前缀提供
# BSD sed:    sed
# GNU sed:    gsed
# BSD tar:    tar
# GNU tar:    gtar
```

---

## �📝 工作原理

### 配置块标记系统

所有脚本修改都使用统一的标记块，带来以下优势：

```bash
### AUTO-<NAME> ###
...配置内容...
### END AUTO-<NAME> ###
```

**优势：**
- 🔄 **幂等性** - 多次运行安全，检查标记避免重复添加
- 🎯 **精确回滚** - 可完全移除对应配置
- 👤 **用户友好** - 保留用户自定义的 .zshrc 配置

**脚本中的标记块：**
- `AUTO-SETUP-CORE` - Oh My Zsh 和 Starship 配置
- `AUTO-RUST` - Rust 环境变量
- `AUTO-PYENV` - Python 环境管理
- `AUTO-FNM` - Node.js 环境管理
- `AUTO-JENV` - Java 环境管理

### 版本管理策略

脚本**只锁定主版本号**，自动安装最新补丁版本：

```bash
PYTHON_MAJOR="3.12"   # → 自动安装 3.12.x 最新（3.12.0, 3.12.1, ...）
NODE_MAJOR="22"       # → 自动安装 22.x 最新（22.10, 22.11, ...）
JAVA_MAJOR="21"       # → 自动安装 21.x 最新（21.0.1, 21.0.2, ...）
```

**好处：**
- ✅ 获得最新安全补丁
- ✅ 避免主版本过时
- ✅ 灵活应对版本更新

### Brewfile 管理

脚本自动将 `brew-packages.txt` 转换为 Homebrew Brewfile：

```bash
# brew-packages.txt
# ===== Formulae (CLI 工具) =====
git              # → 生成 brew "git"
ripgrep          # → 生成 brew "ripgrep"

# ===== Casks (GUI 应用) =====
keka             # → 生成 cask "keka"
```

**解析逻辑：**
- 识别分类标记（包含 `Formulae` 或 `Casks` 关键词）
- 标记下方的包自动归入该分类
- 无需网络请求，完全离线解析

**特点：**
- 增量更新（不覆盖现有 Brewfile）
- 基于明确的分类标记，无需猜测
- 支持注释（# 开头的行自动忽略）
- 离线友好，解析速度快

## 🛡️ 安全性机制

### 1. 自动备份
```bash
# .zshrc 备份（首次修改时）
~/.mac-setup-backup/zshrc.before-*.bak

# Brewfile 备份（回滚时）
~/.mac-setup-backup/Brewfile.before-*.bak
```

### 2. 幂等设计
```bash
# 脚本可安全多次运行
./setup-macos.sh
./setup-macos.sh  # 再次运行，已安装包跳过
./setup-macos.sh  # 完全安全，不会破坏环境
```

### 3. 错误处理
```bash
set -e              # 任何命令失败立即停止
# 关键步骤的检查
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew 安装失败"
  exit 1
fi
```

### 4. 用户确认
```bash
# 初始化前
echo "将执行以下操作："
echo "  ✓ 安装 Homebrew"
echo "  ✓ 安装 Python 3.12"
echo "  ✓ 安装 Node.js 20"
read -p "确认继续？[y/N]: " confirm

# 危险操作（回滚 full 模式）
read -p "确认继续？[y/N]: " confirm
read -p "是否卸载 Homebrew？[y/N]: " remove_brew
```

### 5. GNU 工具兼容性提醒
```bash
# brew-packages.txt
# ===== GNU 工具 =====
# coreutils         # ⚠️ 注意：可能与 macOS 系统工具冲突
# gnu-sed           # ⚠️ 注意：可能与 BSD sed 冲突
# gnu-tar           # ⚠️ 注意：可能与 BSD tar 冲突
```

## 🔧 故障排查

### 问题 1：Homebrew 安装失败

**症状：** `brew: command not found` 或安装中断

**解决方案：**
```bash
# 检查网络连接
ping -c 3 github.com

# 手动安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 添加 Homebrew 到 PATH（Apple Silicon Mac）
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
```

### 问题 2：Python/Node/Java 版本未找到

**症状：** `⚠️ 未找到 Python 3.12 版本`

**解决方案：**
```bash
# 更新版本列表
pyenv install -l | head -20         # 查看可用 Python 版本
fnm list-remote | head -20          # 查看可用 Node.js 版本

# 手动修改 setup-macos.sh
PYTHON_MAJOR="3.11"  # 改为可用版本
```

### 问题 3：.zshrc 配置混乱或重复

**症状：** 终端启动慢或命令执行错误

**解决方案：**
```bash
# 查看备份文件
ls -la ~/.mac-setup-backup/

# 恢复备份
cp ~/.mac-setup-backup/zshrc.before-*.bak ~/.zshrc

# 或重新运行 rollback.sh 清理
./rollback.sh env
```

### 问题 4：脚本执行权限不足

**症状：** `Permission denied: ./setup-macos.sh`

**解决方案：**
```bash
# 添加执行权限
chmod +x setup-macos.sh rollback.sh

# 或使用 bash 直接运行
bash setup-macos.sh
```

### 问题 5：某些软件包安装失败

**症状：** `❌ Error: xxx brew package not found`

**解决方案：**
```bash
# 检查包名是否正确
brew search xxx

# 更新 Homebrew
brew update

# 从 brew-packages.txt 移除该包
vim brew-packages.txt

# 重新运行安装
./setup-macos.sh
```

---

### 文件详细说明

| 文件 | 用途 | 说明 |
|------|------|------|
| `setup-macos.sh` | 主脚本 | 自动化初始化，244 行，完整错误处理 |
| `rollback.sh` | 回滚脚本 | 三级回滚机制，安全可靠 |
| **`brew-packages.txt`** | **配置文件** | **列出需要安装的软件，每个软件都有说明** |
| `README.md` | 文档 | 详细使用指南（本文件，720+ 行） |
| `REVIEW.md` | 技术文档 | 审查和改进详情（供参考） |
| `VERIFICATION.md` | 验证报告 | 最终质量评估（供参考） |
| `test-markers.sh` | 测试工具 | 验证配置块完整性 |
| `check.sh` | 检查工具 | 脚本完整性检查 |

---

### brew-packages.txt 使用建议

**初次使用：**
1. 查看当前列表是否满足需求
2. 移除不需要的软件（注释或删除行）
3. 添加自己需要的软件
4. 运行 `./setup-macos.sh`

**后续维护：**
1. 定期更新软件列表
2. 用 git 追踪变化
3. 在团队中共享配置
4. 收集反馈并改进

**⚠️ 重要提示 - 文件末尾换行符：**

编辑 `brew-packages.txt` 时，**务必在文件末尾保留一个空行**（换行符）。这很关键！

```bash
# ✅ 正确 - 文件末尾有换行符
# ===== Shell & Prompt =====
starship
[此处应有换行符]

# ❌ 错误 - 文件末尾没有换行符
# ===== Shell & Prompt =====
starship[文件结束，无换行符]
```

**为什么重要？**
- Bash 的 `while read -r line` 在末尾没有换行符时，会**跳过最后一行**
- 导致最后几个软件包**不会被读取和安装**
- 结果：starship、VSCode 等工具无法正确安装

**如何确保有换行符：**
```bash
# 方法 1：使用 vim（自动处理）
vim brew-packages.txt
# 按 G 到末尾，按 o 添加新行，然后 ESC 和 :wq 保存

# 方法 2：使用 echo 追加
echo "" >> brew-packages.txt

# 方法 3：检查文件是否以换行符结尾
tail -c 1 brew-packages.txt | od -c
# 输出应该显示 \n（换行符）
```

---

## 💡 最佳实践

### 1. 首次使用流程
```bash
# 1. 克隆并查看
git clone <repo> && cd mac-setup
cat README.md      # 阅读说明
cat brew-packages.txt  # 查看默认软件

# 2. 自定义配置
vim brew-packages.txt  # 添加需要的软件
vim setup-macos.sh     # 修改语言版本（可选）

# 3. 备份现有配置（重要！）
cp ~/.zshrc ~/.zshrc.backup

# 4. 执行初始化
./setup-macos.sh

# 5. 验证结果
exec zsh
python --version && node --version && java -version
```

### 2. 遇到问题时
```bash
# 查看错误日志
./setup-macos.sh 2>&1 | tee setup.log

# 手动修复问题后，可以再次运行（安全）
./setup-macos.sh

# 如果想回滚
./rollback.sh soft   # 先禁用（最安全）
# 修复问题后
./rollback.sh env    # 再恢复原环境
```

### 3. 多人团队使用
```bash
# 统一开发环境
git clone <repo> mac-setup
cd mac-setup

# 所有团队成员运行相同命令
./setup-macos.sh

# 保证所有人拥有相同的环境配置
# Python 3.12、Node.js 20、Java 21、Rust 最新...
```

### 4. 版本控制管理
```bash
# 在 git 中管理这些脚本
git add setup-macos.sh brew-packages.txt
git commit -m "Update: add new packages and upgrade Python to 3.13"
git push

# 追踪所有环境变化历史
git log --oneline
```

### 5. 定期更新
```bash
# 每月检查一次新版本
brew update
pyenv install -l | grep "^  3.12" | tail -3
fnm list-remote | grep "^v22" | tail -3

# 如有重要安全更新，修改版本号
vim setup-macos.sh
# PYTHON_MAJOR="3.12.1" 改为 "3.13"

# 重新运行（安全）
./setup-macos.sh
```

## 🌍 兼容性

| 系统 | 状态 | 备注 |
|------|------|------|
| macOS (Intel) | ✅ 完全支持 | 推荐使用 |
| macOS (Apple Silicon) | ✅ 完全支持 | 需要 Homebrew 在 /opt/homebrew |
| macOS Monterey+ | ✅ 推荐 | 3.12+ 版本可用 |
| Ubuntu 20.04+ | ✅ 基本支持 | 需要 apt 安装依赖 |
| 其他 Linux | ⚠️ 有限支持 | 可能需要手动调整 |

## 📖 文档导航

- **新用户** → 从 [快速开始](#-快速开始) 开始
- **想了解软件** → 查看 [软件包详细说明](#-软件包详细说明)
- **开发者** → 查看 [工作原理](#-工作原理)
- **遇到问题** → 参考 [故障排查](#-故障排查)
- **深入了解** → 阅读 `REVIEW.md` 和 `VERIFICATION.md`

---

## 🎯 快速参考

### brew-packages.txt 的作用
```
定义你的开发环境 → 自动安装所有软件 → 版本控制追踪 → 团队协作共享
```

### 文件关系图
```
brew-packages.txt (你的配置)
       ↓
setup-macos.sh (读取和执行)
       ↓
Brewfile + Shell配置 (实际环境)
       ↓
rollback.sh (需要时撤销)
```

### 常用命令速查
```bash
# 初始化
./setup-macos.sh

# 回滚（三种选择）
./rollback.sh soft   # 仅禁用配置
./rollback.sh env    # 删除环境（推荐）
./rollback.sh full   # 完全卸载

# 修改软件列表
vim brew-packages.txt
./setup-macos.sh     # 重新运行安装

# 版本控制
git add brew-packages.txt
git commit -m "Update packages"
```

## 🤝 贡献建议

欢迎改进和建议！您可以：
- 📝 修改 `brew-packages.txt` 添加新软件
- 🐛 发现 bug 时创建 issue
- 💡 建议新功能或优化
- 📢 分享给其他开发者
- 💬 提出改进文档的建议

---

## 📄 许可证

MIT License - 自由使用和修改


