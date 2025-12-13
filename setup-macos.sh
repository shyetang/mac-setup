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
if [ ! -f "brew-packages.txt" ]; then
  echo "❌ 错误：未找到 brew-packages.txt 文件"
  exit 1
fi

touch "$BREWFILE"

while read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  if ! grep -q "\"$pkg\"" "$BREWFILE"; then
    if brew info --cask "$pkg" >/dev/null 2>&1; then
      echo "cask \"$pkg\"" >> "$BREWFILE"
    else
      echo "brew \"$pkg\"" >> "$BREWFILE"
    fi
  fi
done < brew-packages.txt

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

add_block "### AUTO-SETUP-CORE ###" '
### AUTO-SETUP-CORE ###
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git z sudo extract fzf)
source $ZSH/oh-my-zsh.sh

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
### END AUTO-SETUP-CORE ###
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
  "$(brew --prefix)/opt/fzf/install" --all
fi

echo ""
echo "✅ 初始化完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 后续步骤："
echo "  1. 重新打开终端（或执行: exec zsh）"
echo "  2. 验证环境: python --version, node --version, java -version"
echo "  3. 如需回滚，执行: ./rollback.sh [soft|env|full]"
echo ""