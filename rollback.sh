#!/usr/bin/env bash
set -e

MODE="$1" # soft | env | full
ZSHRC="$HOME/.zshrc"
BREWFILE="$HOME/Brewfile"
BACKUP_DIR="$HOME/.mac-setup-backup"

mkdir -p "$BACKUP_DIR"

usage() {
	echo "用法: ./rollback.sh [soft|env|full]"
	exit 1
}

# ============================================
# 恢复原始 Oh My Zsh 配置（复用函数）
# ============================================
restore_original_config() {
	if [ ! -f "$ZSHRC" ]; then
		return
	fi

	if [ -f "$BACKUP_DIR/original-plugins.latest" ] || [ -f "$BACKUP_DIR/original-theme.latest" ]; then
		echo "▶ 恢复原始 Oh My Zsh 配置"

		# 恢复原始插件
		if [ -f "$BACKUP_DIR/original-plugins.latest" ]; then
			original_plugins=$(cat "$BACKUP_DIR/original-plugins.latest")
			if [ -n "$original_plugins" ]; then
				echo "  恢复插件: $original_plugins"
				awk -v plugins="$original_plugins" '
          /^plugins=\(/ {
            print "plugins=(" plugins ")"
            next
          }
          { print }
        ' "$ZSHRC" >"$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
			fi
		fi

		# 恢复原始主题
		if [ -f "$BACKUP_DIR/original-theme.latest" ]; then
			original_theme=$(cat "$BACKUP_DIR/original-theme.latest")
			if [ -n "$original_theme" ]; then
				echo "  恢复主题: $original_theme"
				awk -v theme="$original_theme" '
          /^ZSH_THEME=/ {
            print "ZSH_THEME=\"" theme "\""
            next
          }
          { print }
        ' "$ZSHRC" >"$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
			fi
		fi
	else
		echo "  ⚠️ 未找到原始配置备份，跳过恢复"
	fi
}

[[ "$MODE" =~ ^(soft|env|full)$ ]] || usage

echo "▶ 回滚模式: $MODE"

# ==================================================
# soft：仅停用自动配置（最安全）
# ==================================================
if [ "$MODE" = "soft" ]; then
	echo "▶ 禁用 AUTO-SETUP 配置块"

	if [ -f "$ZSHRC" ]; then
		awk '{gsub(/^### AUTO-/, "### DISABLED-AUTO-"); print}' "$ZSHRC" >"$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
	fi

	echo "✅ soft 回滚完成（不删除任何软件）"
	echo "👉 重新打开终端生效"
	exit 0
fi

# ==================================================
# env：恢复用户环境（推荐）
# ==================================================
if [ "$MODE" = "env" ]; then
	echo "▶ 执行 env 回滚（恢复用户环境）"

	if [ -f "$ZSHRC" ]; then
		echo "▶ 备份 .zshrc"
		cp "$ZSHRC" "$BACKUP_DIR/zshrc.before-env.$(date +%Y%m%d%H%M%S)"

		echo "▶ 移除 AUTO-SETUP 配置块"
		awk '/^### AUTO-/{flag=1} /^### END AUTO-/{flag=0;next} !flag' "$ZSHRC" >"$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

		# 调用恢复函数
		restore_original_config
	fi

	echo "▶ 删除语言与 shell 相关目录"
	rm -rf \
		"$HOME/.oh-my-zsh" \
		"$HOME/.cargo" \
		"$HOME/.pyenv" \
		"$HOME/.fnm" \
		"$HOME/.jenv" \
		"$HOME/go" # GOPATH

	echo "✅ env 回滚完成"
	echo "👉 重新打开终端"
	exit 0
fi

# ==================================================
# full：完全回滚（高风险）
# ==================================================
if [ "$MODE" = "full" ]; then
	echo "⚠️ 即将执行 FULL 回滚（危险）"
	echo "这会卸载 Brewfile 中的软件，并删除用户环境"

	read -p "确认继续？[y/N]: " confirm
	[[ "$confirm" = "y" ]] || exit 1

	if [ -f "$ZSHRC" ]; then
		echo "▶ 备份 .zshrc"
		cp "$ZSHRC" "$BACKUP_DIR/zshrc.before-full.$(date +%Y%m%d%H%M%S)"

		echo "▶ 移除 AUTO-SETUP 配置块"
		awk '/^### AUTO-/{flag=1} /^### END AUTO-/{flag=0;next} !flag' "$ZSHRC" >"$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"

		# 调用恢复函数
		restore_original_config
	fi

	if [ -f "$BREWFILE" ]; then
		echo "▶ 备份 Brewfile"
		cp "$BREWFILE" "$BACKUP_DIR/Brewfile.before-full.$(date +%Y%m%d%H%M%S)"

		echo "▶ 卸载 Brewfile 中的软件"
		brew bundle cleanup --force || echo "⚠️ Brewfile cleanup 失败（可能文件为空）"
	fi

	echo "▶ 删除用户环境目录"
	rm -rf \
		"$HOME/.oh-my-zsh" \
		"$HOME/.cargo" \
		"$HOME/.pyenv" \
		"$HOME/.fnm" \
		"$HOME/.jenv" \
		"$HOME/go" # GOPATH

	echo
	read -p "是否卸载 Homebrew？[y/N]: " remove_brew
	if [ "$remove_brew" = "y" ]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
	fi

	echo ""
	echo "✅ full 回滚完成！"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "📝 建议后续步骤："
	echo "  1. 重新打开终端"
	echo "  2. 备份文件已保存至: $BACKUP_DIR"
	echo ""
fi
