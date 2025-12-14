#!/usr/bin/env bash
# 测试备份和恢复功能

set -e

echo "🧪 测试备份和恢复系统"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 备份当前 .zshrc
ORIGINAL_ZSHRC="$HOME/.zshrc.backup-before-test"
if [ -f "$HOME/.zshrc" ]; then
  echo "▶ 备份当前 .zshrc"
  cp "$HOME/.zshrc" "$ORIGINAL_ZSHRC"
fi

# 创建测试 .zshrc
echo "▶ 创建测试环境"
cat > "$HOME/.zshrc" << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker autojump)
source $ZSH/oh-my-zsh.sh

# 用户自定义配置
alias ll='ls -lah'
export EDITOR=vim
EOF

echo "  测试文件已创建："
echo "  - 主题: robbyrussell"
echo "  - 插件: git docker autojump"
echo ""

# 测试 1：检测原始配置备份
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试 1：检测和备份原始配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 直接定义检测函数（从 setup-macos.sh 提取）
ZSHRC="$HOME/.zshrc"
BACKUP_DIR="$HOME/.mac-setup-backup"

extract_existing_plugins() {
  if [ ! -f "$ZSHRC" ]; then
    echo ""
    return
  fi
  
  awk '
    /^### AUTO-/ { in_auto=1; next }
    /^### END AUTO-/ { in_auto=0; next }
    !in_auto && /^plugins=\(/ {
      line = $0
      sub(/^plugins=\(/, "", line)
      sub(/\).*$/, "", line)
      print line
      exit
    }
  ' "$ZSHRC"
}

extract_existing_theme() {
  if [ ! -f "$ZSHRC" ]; then
    echo ""
    return
  fi
  
  awk '
    /^### AUTO-/ { in_auto=1; next }
    /^### END AUTO-/ { in_auto=0; next }
    !in_auto && /^ZSH_THEME=/ {
      line = $0
      sub(/^ZSH_THEME="/, "", line)
      sub(/".*$/, "", line)
      print line
      exit
    }
  ' "$ZSHRC"
}

# 测试检测功能
plugins=$(extract_existing_plugins)
theme=$(extract_existing_theme)

echo "✅ 检测到插件: $plugins"
echo "✅ 检测到主题: $theme"

# 执行备份
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
  echo "$plugins" > "$BACKUP_DIR/original-plugins.$TIMESTAMP"
  echo "$theme" > "$BACKUP_DIR/original-theme.$TIMESTAMP"
  ln -sf "$BACKUP_DIR/original-plugins.$TIMESTAMP" "$BACKUP_DIR/original-plugins.latest"
  ln -sf "$BACKUP_DIR/original-theme.$TIMESTAMP" "$BACKUP_DIR/original-theme.latest"
  
  echo "✅ 备份已创建："
  echo "  - $BACKUP_DIR/original-plugins.latest"
  echo "  - $BACKUP_DIR/original-theme.latest"

echo ""

# 测试 2：模拟配置修改
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试 2：模拟 setup-macos.sh 修改配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 修改 .zshrc（模拟 setup-macos.sh 的行为）
sed -i.test 's/plugins=(git docker autojump)/plugins=(autojump colored-man-pages docker extract fzf git sudo)/' "$HOME/.zshrc"
sed -i.test 's/ZSH_THEME="robbyrussell"/ZSH_THEME=""/' "$HOME/.zshrc"

echo "✅ 配置已修改："
grep "^plugins=" "$HOME/.zshrc"
grep "^ZSH_THEME=" "$HOME/.zshrc"
echo ""

# 测试 3：测试恢复功能
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "测试 3：测试 rollback.sh 恢复功能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$BACKUP_DIR/original-plugins.latest" ]; then
  original_plugins=$(cat "$BACKUP_DIR/original-plugins.latest")
  original_theme=$(cat "$BACKUP_DIR/original-theme.latest")
  
  echo "  备份的原始配置："
  echo "  - 插件: $original_plugins"
  echo "  - 主题: $original_theme"
  echo ""
  
  # 恢复插件
  awk -v plugins="$original_plugins" '
    /^plugins=\(/ {
      print "plugins=(" plugins ")"
      next
    }
    { print }
  ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  
  # 恢复主题
  awk -v theme="$original_theme" '
    /^ZSH_THEME=/ {
      print "ZSH_THEME=\"" theme "\""
      next
    }
    { print }
  ' "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  
  echo "✅ 配置已恢复："
  grep "^plugins=" "$HOME/.zshrc"
  grep "^ZSH_THEME=" "$HOME/.zshrc"
  echo ""
  
  # 验证
  restored_plugins=$(extract_existing_plugins 2>/dev/null || grep "^plugins=" "$HOME/.zshrc" | sed 's/plugins=(\(.*\))/\1/')
  restored_theme=$(extract_existing_theme 2>/dev/null || grep "^ZSH_THEME=" "$HOME/.zshrc" | sed 's/ZSH_THEME="\(.*\)"/\1/')
  
  if [ "$restored_plugins" = "$original_plugins" ] && [ "$restored_theme" = "$original_theme" ]; then
    echo "✅ 验证通过：配置已完全恢复！"
  else
    echo "❌ 验证失败："
    echo "  期望插件: $original_plugins"
    echo "  实际插件: $restored_plugins"
    echo "  期望主题: $original_theme"
    echo "  实际主题: $restored_theme"
  fi
else
  echo "❌ 未找到备份文件"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 测试完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 恢复原始 .zshrc
if [ -f "$ORIGINAL_ZSHRC" ]; then
  echo "▶ 恢复原始 .zshrc"
  mv "$ORIGINAL_ZSHRC" "$HOME/.zshrc"
fi

# 清理测试文件
rm -f "$HOME/.zshrc.test"

echo "✅ 清理完成"
