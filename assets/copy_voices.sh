#!/bin/bash

# 从 OpenIdea 目录复制 Kokoro 语音文件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOICE_DIR="$SCRIPT_DIR/voices"

# 源目录
SOURCE_DIR="$HOME/Documents/OpenIdea/kokoro/kokoro.js/voices"

echo "📦 复制 Kokoro 语音文件..."
echo "源目录：$SOURCE_DIR"
echo "目标目录：$VOICE_DIR"

# 创建目标目录
mkdir -p "$VOICE_DIR"

# 检查源目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 源目录不存在：$SOURCE_DIR"
    exit 1
fi

# 复制所有 .bin 文件
echo "正在复制语音文件..."
cp "$SOURCE_DIR"/*.bin "$VOICE_DIR/"

echo ""
echo "✅ 语音文件复制完成！"
echo ""
echo "已复制的语音文件:"
ls -lh "$VOICE_DIR"/*.bin | awk '{print "  - " $9 " (" $5 ")"}'

echo ""
echo "推荐使用的语音:"
echo "  - af_heart.bin (女声，高质量)"
echo "  - af_bella.bin (女声，自然)"
echo "  - am_michael.bin (男声)"
echo "  - zm_yunxi.bin (中文男声)"
echo "  - zf_xiaoni.bin (中文女声)"
