#!/usr/bin/env bash

# 这个脚本验证所有 AUTO- 标记块是否正确配对

echo "🔍 检查配置块标记..."
echo ""

markers=$(grep -o "### AUTO-[A-Z]*.*###" setup-macos.sh 2>/dev/null | sed 's/ ###.*//' | sed 's/### AUTO-//')

for marker in $markers; do
  start=$(grep -c "### AUTO-${marker} ###" setup-macos.sh)
  end=$(grep -c "### END AUTO-${marker} ###" setup-macos.sh)
  
  if [ "$start" -eq "$end" ] && [ "$start" -gt 0 ]; then
    echo "✅ $marker: 配置块完整（$start 对）"
  else
    echo "❌ $marker: 配置块不匹配（开始: $start, 结束: $end）"
  fi
done

echo ""
echo "🔍 检查 rollback.sh 的处理能力..."

# 检查 rollback.sh 是否能处理这些标记
if grep -q "AUTO-" rollback.sh; then
  echo "✅ rollback.sh 包含 AUTO- 处理逻辑"
else
  echo "❌ rollback.sh 可能无法处理 AUTO- 块"
fi

echo ""
echo "✅ 检查完成"
