#!/usr/bin/env bash
set -e

# ===============================
# ⭐ 用户可配置区（最重要）
# ===============================
INSTALL_NODE=1
INSTALL_PYTHON=1
INSTALL_RUST=1
INSTALL_JAVA=1

# ---- 语言版本策略（只锁大版本）----
PYTHON_MAJOR="3.12"   # → 安装 3.12.x 最新
NODE_MAJOR="22"       # → 安装 22.x 最新
JAVA_MAJOR="21"       # → 安装 21.x 最新（LTS）

SETUP_DIR="$HOME/mac-setup"
BREWFILE="$HOME/Brewfile"
ZSHRC="$HOME/.zshrc"

echo "📋 macOS 初始化脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "将执行以下操作："
echo "  ✓ 安装/更新 Homebrew"
echo "  ✓ 安装 Brewfile 中的软件包"
echo "  ✓ 安装 Oh My Zsh 和配置"
echo "  ✓ 安装编程语言环境："
[ "$INSTALL_RUST" = "1" ] && echo "    - Rust"
[ "$INSTALL_PYTHON" = "1" ] && echo "    - Python ${PYTHON_MAJOR}"
[ "$INSTALL_NODE" = "1" ] && echo "    - Node.js ${NODE_MAJOR}"
[ "$INSTALL_JAVA" = "1" ] && echo "    - Java ${JAVA_MAJOR}"
echo ""
read -p "确认继续？[y/N]: " confirm
[[ "$confirm" = "y" ]] || exit 0

mkdir -p "$SETUP_DIR"
cd "$SETUP_DIR"

# ===============================
# 1️⃣ Homebrew
# ===============================
if ! command -v brew >/dev/null 2>&1; then
  echo "▶ 安装 Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "❌ Homebrew 安装失败"
    exit 1
  }
fi

echo "▶ 更新 Homebrew"
brew update || echo "⚠️ Homebrew 更新失败（可能是网络问题）"

# ===============================
# 2️⃣ 合并 Brewfile（不覆盖）
# ===============================
# 获取执行脚本时的目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/brew-packages.txt"

if [ ! -f "$PACKAGES_FILE" ]; then
  echo "❌ 错误：未找到 brew-packages.txt 文件"
  echo "   期望位置: $PACKAGES_FILE"
  exit 1
fi

touch "$BREWFILE"

# 追踪当前所在分类
current_type=""

while read -r line; do
  # 跳过空行
  [[ -z "$line" ]] && continue
  
  # 识别分类标记
  if [[ "$line" =~ ^#.*Formulae ]]; then
    current_type="formula"
    continue
  elif [[ "$line" =~ ^#.*Casks ]]; then
    current_type="cask"
    continue
  fi
  
  # 跳过其他注释行
  [[ "$line" =~ ^# ]] && continue
  
  # 去掉行中的注释部分和前后空格
  pkg=$(echo "$line" | sed 's/#.*//' | xargs)
  
  # 再次检查去掉注释后是否为空
  [[ -z "$pkg" ]] && continue
  
  # 根据分类添加到 Brewfile
  if ! grep -q "\"$pkg\"" "$BREWFILE"; then
    if [ "$current_type" = "formula" ]; then
      echo "brew \"$pkg\"" >> "$BREWFILE"
    elif [ "$current_type" = "cask" ]; then
      echo "cask \"$pkg\"" >> "$BREWFILE"
    fi
  fi
done < "$PACKAGES_FILE"

echo "▶ 安装 Brewfile 软件"
brew bundle --file="$BREWFILE" || echo "⚠️ 部分软件包安装失败（可能已安装或网络问题）"

# ===============================
# 3️⃣ Oh My Zsh（不破坏 zshrc）
# ===============================
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "▶ 安装 Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ===============================
# 4️⃣ 安全追加 zsh 配置（标记块）
# ===============================
add_block() {
  local marker="$1"
  local content="$2"

  if ! grep -q "$marker" "$ZSHRC" 2>/dev/null; then
    {
      echo ""
      printf '%s\n' "$content"
    } >> "$ZSHRC"
  fi
}

# ===============================
# 智能配置检测函数
# ===============================

# 检测是否已有 Oh My Zsh 配置（排除 AUTO 块）
detect_omz_config() {
  if [ ! -f "$ZSHRC" ]; then
    return 1
  fi
  
  # 检查是否存在 Oh My Zsh 配置，但不在 AUTO 块内
  awk '
    /^### AUTO-/ { in_auto=1; next }
    /^### END AUTO-/ { in_auto=0; next }
    !in_auto && /^(export ZSH=|source \$ZSH\/oh-my-zsh\.sh)/ { found=1; exit }
    END { exit !found }
  ' "$ZSHRC"
}

# 提取现有插件列表（排除 AUTO 块）
extract_existing_plugins() {
  if [ ! -f "$ZSHRC" ]; then
    echo ""
    return
  fi
  
  awk '
    /^### AUTO-/ { in_auto=1; next }
    /^### END AUTO-/ { in_auto=0; next }
    !in_auto && /^plugins=\(/ {
      # 提取括号内的内容
      line = $0
      sub(/^plugins=\(/, "", line)
      sub(/\).*$/, "", line)
      print line
      exit
    }
  ' "$ZSHRC"
}

# 合并插件列表（去重）
merge_plugins() {
  local existing="$1"
  local new_plugins="git sudo extract fzf colored-man-pages"
  
  # 合并并去重
  echo "$existing $new_plugins" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

# 提取现有主题设置（排除 AUTO 块）
extract_existing_theme() {
  if [ ! -f "$ZSHRC" ]; then
    echo ""
    return
  fi
  
  awk '
    /^### AUTO-/ { in_auto=1; next }
    /^### END AUTO-/ { in_auto=0; next }
    !in_auto && /^ZSH_THEME=/ {
      # 提取引号内的内容
      line = $0
      sub(/^ZSH_THEME="/, "", line)
      sub(/".*$/, "", line)
      print line
      exit
    }
  ' "$ZSHRC"
}

# 智能配置 Oh My Zsh
if detect_omz_config; then
  echo "▶ 检测到现有 Oh My Zsh 配置，执行智能合并"
  
  # 提取现有配置
  existing_plugins=$(extract_existing_plugins)
  existing_theme=$(extract_existing_theme)
  
  echo "  现有插件: ${existing_plugins:-无}"
  echo "  现有主题: ${existing_theme:-无}"
  
  # 备份原始配置（用于回滚）
  BACKUP_DIR="$HOME/.mac-setup-backup"
  mkdir -p "$BACKUP_DIR"
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  
  echo "▶ 备份原始配置到 $BACKUP_DIR"
  echo "$existing_plugins" > "$BACKUP_DIR/original-plugins.$TIMESTAMP"
  echo "$existing_theme" > "$BACKUP_DIR/original-theme.$TIMESTAMP"
  
  # 创建符号链接指向最新备份
  ln -sf "$BACKUP_DIR/original-plugins.$TIMESTAMP" "$BACKUP_DIR/original-plugins.latest"
  ln -sf "$BACKUP_DIR/original-theme.$TIMESTAMP" "$BACKUP_DIR/original-theme.latest"
  
  # 合并插件
  merged_plugins=$(merge_plugins "$existing_plugins")
  echo "  合并后插件: $merged_plugins"
  
  # 决定主题策略
  use_starship="n"
  if [ -n "$existing_theme" ] && [ "$existing_theme" != '""' ] && [ "$existing_theme" != "" ]; then
    echo ""
    echo "  💡 脚本推荐使用 starship（现代化命令行提示符）"
    echo "     - 更美观的终端提示"
    echo "     - 自动显示 git 分支、环境状态"
    echo "     - 高性能（Rust 编写）"
    read -p "  是否改用 starship？[y/N]: " use_starship
  else
    # 用户无主题或主题为空，默认使用 starship
    use_starship="y"
  fi
  
  # 生成配置内容
  if [ "$use_starship" = "y" ]; then
    starship_config='
if command -v starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi'
    final_theme=""
  else
    starship_config=""
    final_theme="$existing_theme"
  fi
  
  # 只在不存在 AUTO-SETUP-CORE 时添加
  # 注意：因为用户已有 OMZ 配置（包含 source），此处只需覆盖 plugins 和添加 starship
  if ! grep -q "### AUTO-SETUP-CORE ###" "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" <<EOF

### AUTO-SETUP-CORE ###
# 插件列表已在上方 plugins=(...) 行中更新
# 此块仅用于 starship 配置和标记脚本修改范围
$starship_config
### END AUTO-SETUP-CORE ###
EOF
  fi
  
  # 更新原有配置中的插件列表（排除 AUTO 块内的）
  awk -v new_plugins="$merged_plugins" '
    /^### AUTO-/ { in_auto=1; print; next }
    /^### END AUTO-/ { in_auto=0; print; next }
    !in_auto && /^plugins=\(/ {
      print "plugins=(" new_plugins ")"
      next
    }
    { print }
  ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  
  # 如果选择使用 starship，清空原有主题
  if [ "$use_starship" = "y" ]; then
    awk '
      /^### AUTO-/ { in_auto=1; print; next }
      /^### END AUTO-/ { in_auto=0; print; next }
      !in_auto && /^ZSH_THEME=/ {
        print "ZSH_THEME=\"\""
        next
      }
      { print }
    ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  fi
  
else
  # 无现有配置，使用完整配置块
  echo "▶ 未检测到 Oh My Zsh 配置，添加完整配置块"
  
  add_block "### AUTO-SETUP-CORE ###" '
### AUTO-SETUP-CORE ###
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git sudo extract fzf colored-man-pages)
source $ZSH/oh-my-zsh.sh

if command -v starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
### END AUTO-SETUP-CORE ###
'
fi

add_block "### AUTO-ZOXIDE ###" '
### AUTO-ZOXIDE ###
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
### END AUTO-ZOXIDE ###
'

# ===============================
# 5️⃣ 语言环境（统一策略）
# ===============================

# ---------- Rust ----------
if [ "$INSTALL_RUST" = "1" ]; then
  if ! command -v rustup >/dev/null 2>&1; then
    echo "▶ 安装 Rust"
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
  fi

  add_block "### AUTO-RUST ###" '
### AUTO-RUST ###
export PATH="$HOME/.cargo/bin:$PATH"
### END AUTO-RUST ###
'
fi

# ---------- Python ----------
if [ "$INSTALL_PYTHON" = "1" ]; then
  if ! command -v pyenv >/dev/null 2>&1; then
    echo "▶ 安装 pyenv"
    brew install pyenv
  fi

  echo "▶ 安装 Python ${PYTHON_MAJOR}.x 最新版本"
  latest_python=$(pyenv install -l | \
    sed "s/^[[:space:]]*//" | \
    grep "^${PYTHON_MAJOR}\.[0-9]\+$" | \
    tail -n 1)

  if [ -n "$latest_python" ]; then
    pyenv install -s "$latest_python"
    pyenv global "$latest_python"
  else
    echo "⚠️ 未找到 Python ${PYTHON_MAJOR} 版本"
  fi

  add_block "### AUTO-PYENV ###" '
### AUTO-PYENV ###
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
### END AUTO-PYENV ###
'
fi

# ---------- Node.js ----------
if [ "$INSTALL_NODE" = "1" ]; then
  if ! command -v fnm >/dev/null 2>&1; then
    echo "▶ 安装 fnm"
    brew install fnm
  fi

  # 初始化 fnm 环境
  eval "$(fnm env --use-on-cd)"

  echo "▶ 安装 Node.js ${NODE_MAJOR}.x 最新版本"
  latest_node=$(fnm list-remote | \
    grep "^v${NODE_MAJOR}\." | \
    tail -n 1)

  if [ -n "$latest_node" ]; then
    fnm install "$latest_node"
    fnm default "$latest_node"
  else
    echo "⚠️ 未找到 Node.js ${NODE_MAJOR} 版本"
  fi

  add_block "### AUTO-FNM ###" '
### AUTO-FNM ###
eval "$(fnm env --use-on-cd)"
### END AUTO-FNM ###
'
fi

# ---------- Java ----------
if [ "$INSTALL_JAVA" = "1" ]; then
  if ! command -v jenv >/dev/null 2>&1; then
    echo "▶ 安装 jenv"
    brew install jenv
  fi

  echo "▶ 安装 OpenJDK ${JAVA_MAJOR}"
  brew install "openjdk@${JAVA_MAJOR}"

  # 方法1：使用 brew 提供的路径
  JAVA_HOME_PATH="$(brew --prefix openjdk@${JAVA_MAJOR})/libexec/openjdk.jdk/Contents/Home"
  
  # 方法2（备选）：使用系统 /usr/libexec/java_home
  if [ ! -d "$JAVA_HOME_PATH" ]; then
    JAVA_HOME_PATH="$(/usr/libexec/java_home -v "${JAVA_MAJOR}" 2>/dev/null || echo "")"
  fi
  
  if [ -n "$JAVA_HOME_PATH" ] && [ -d "$JAVA_HOME_PATH" ]; then
    jenv add "$JAVA_HOME_PATH" 2>/dev/null || true
    
    # 验证 jenv 中有对应版本后再设置全局版本
    if jenv versions 2>/dev/null | grep -q "${JAVA_MAJOR}"; then
      jenv global "${JAVA_MAJOR}"
    fi
  else
    echo "⚠️ 未找到有效的 Java ${JAVA_MAJOR} 安装路径"
  fi

  add_block "### AUTO-JENV ###" '
### AUTO-JENV ###
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
### END AUTO-JENV ###
'
fi

# ===============================
# 6️⃣ fzf 补全（幂等）
# ===============================
if [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  echo "▶ 配置 fzf 补全"
  # --no-update-rc 避免重复添加到 .zshrc（已通过 OMZ fzf 插件配置）
  # --key-bindings --completion 启用快捷键和补全
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

echo ""
echo "✅ 初始化完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 后续步骤："
echo "  1. 重新打开终端（或执行: exec zsh）"
echo "  2. 验证环境: python --version, node --version, java -version"
echo "  3. 如需回滚，执行: ./rollback.sh [soft|env|full]"
echo ""