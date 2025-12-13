#!/bin/bash

# macOS Setup 脚本检查清单

echo "🔍 macOS Setup 脚本完整性检查"
echo "=================================="
echo ""

# 1. 文件完整性
echo "📁 文件完整性检查"
files=(
  "setup-macos.sh"
  "rollback.sh"
  "brew-packages.txt"
  "README.md"
  "REVIEW.md"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    size=$(wc -c < "$file" | tr -d ' ')
    lines=$(wc -l < "$file" | tr -d ' ')
    echo "  ✅ $file ($lines 行, $size 字节)"
  else
    echo "  ❌ $file 缺失"
  fi
done

echo ""
echo "🔧 语法检查"

# 2. bash 语法检查
for script in setup-macos.sh rollback.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "  ✅ $script 语法正确"
  else
    echo "  ⚠️  $script 语法检查失败（可能需要手动验证）"
  fi
done

echo ""
echo "📋 关键内容检查"

# 3. 内容检查
checks=(
  "setup-macos.sh:INSTALL_NODE=1"
  "setup-macos.sh:add_block"
  "setup-macos.sh:### AUTO-"
  "rollback.sh:soft"
  "rollback.sh:env"
  "rollback.sh:full"
  "brew-packages.txt:git"
  "README.md:快速开始"
)

for check in "${checks[@]}"; do
  file=${check%:*}
  pattern=${check#*:}
  
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ $file 包含 '$pattern'"
  else
    echo "  ❌ $file 缺少 '$pattern'"
  fi
done

echo ""
echo "✨ 配置块检查"

# 4. 配置块完整性
blocks=(
  "SETUP-CORE"
  "ZOXIDE"
  "RUST"
  "PYENV"
  "FNM"
  "JENV"
)

for block in "${blocks[@]}"; do
  start=$(grep -c "### AUTO-${block} ###" setup-macos.sh 2>/dev/null || echo 0)
  end=$(grep -c "### END AUTO-${block} ###" setup-macos.sh 2>/dev/null || echo 0)
  
  if [ "$start" -eq "$end" ] && [ "$start" -gt 0 ]; then
    echo "  ✅ AUTO-${block} 配置块正确"
  else
    echo "  ⚠️  AUTO-${block} 配置块不匹配"
  fi
done

echo ""
echo "🎯 功能完整性"

# 5. 功能检查
features=(
  "setup-macos.sh:确认继续"
  "setup-macos.sh:brew update"
  "setup-macos.sh:pyenv"
  "setup-macos.sh:fnm"
  "setup-macos.sh:java -version"
  "rollback.sh:$BACKUP_DIR"
  "rollback.sh:jenv"
  "README.md:回滚"
)

for feature in "${features[@]}"; do
  file=${feature%:*}
  pattern=${feature#*:}
  
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  ✅ 已实现：$pattern"
  else
    echo "  ❌ 缺少：$pattern"
  fi
done

echo ""
echo "=================================="
echo "✅ 检查完成！"
echo ""
echo "📖 查看完整审查报告："
echo "   cat REVIEW.md"
echo ""
echo "🚀 准备开始？"
echo "   1. 编辑 brew-packages.txt"
echo "   2. 修改 setup-macos.sh 顶部配置（可选）"
echo "   3. 运行 ./setup-macos.sh"
