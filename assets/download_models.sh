#!/bin/bash

# Kokoro TTS 模型下载/复制脚本
# 支持从 HuggingFace 下载或从 OpenIdea 目录复制

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 Kokoro TTS 模型准备..."
echo "目录：$SCRIPT_DIR"

# 检查 OpenIdea 目录
OPENIDEA_DIR="$HOME/Documents/OpenIdea/kokoro"
OPENIDEA_MODEL=""
OPENIDEA_VOICES=""

# 查找 OpenIdea 中的模型文件
if [ -d "$OPENIDEA_DIR" ]; then
    echo "🔍 检查 OpenIdea 目录：$OPENIDEA_DIR"
    
    # 查找 onnx 文件
    ONNX_FILE=$(find "$OPENIDEA_DIR" -name "*.onnx" -type f 2>/dev/null | head -1)
    if [ -n "$ONNX_FILE" ]; then
        OPENIDEA_MODEL="$ONNX_FILE"
        echo "✓ 找到 ONNX 模型：$ONNX_FILE"
    fi
    
    # 查找 voices .bin 文件
    VOICES_DIR="$OPENIDEA_DIR/kokoro.js/voices"
    if [ -d "$VOICES_DIR" ]; then
        OPENIDEA_VOICES="$VOICES_DIR"
        VOICE_COUNT=$(ls -1 "$VOICES_DIR"/*.bin 2>/dev/null | wc -l)
        echo "✓ 找到语音目录：$VOICES_DIR ($VOICE_COUNT 个语音文件)"
    fi
fi

# 检查本地是否已有模型
if [ -f "kokoro-v1.0.int8.onnx" ] && [ -f "voices-v1.0.bin" ]; then
    echo ""
    echo "✅ 模型文件已存在，跳过下载"
    ls -lh kokoro-v1.0.int8.onnx voices-v1.0.bin
    exit 0
fi

# 优先从 OpenIdea 复制
if [ -n "$OPENIDEA_MODEL" ] && [ -n "$OPENIDEA_VOICES" ]; then
    echo ""
    echo "📋 从 OpenIdea 复制模型文件..."
    
    # 复制主模型（找到哪个就用哪个）
    if [ -f "$OPENIDEA_MODEL" ]; then
        MODEL_BASENAME=$(basename "$OPENIDEA_MODEL")
        echo "复制模型：$MODEL_BASENAME"
        cp "$OPENIDEA_MODEL" "./kokoro-model.onnx"
    fi
    
    # 复制基础语音文件（创建 voices-v1.0.bin 或使用现有 .bin 文件）
    if [ -f "$OPENIDEA_VOICES/af_heart.bin" ]; then
        echo "复制语音文件：af_heart.bin 等"
        cp "$OPENIDEA_VOICES"/*.bin "./" 2>/dev/null || true
        # 创建 voices-v1.0.bin 符号链接或复制
        if [ ! -f "voices-v1.0.bin" ]; then
            cp "$OPENIDEA_VOICES/af_heart.bin" "voices-v1.0.bin"
        fi
    fi
    
    echo ""
    echo "✅ 从 OpenIdea 复制完成！"
    ls -lh *.onnx *.bin 2>/dev/null | head -10
    exit 0
fi

# 从 HuggingFace 下载
echo ""
echo "⬇️  OpenIdea 中未找到模型，从 HuggingFace 下载..."

if command -v huggingface-cli &> /dev/null; then
    echo "✓ 使用 huggingface-cli 下载"
    huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX kokoro-v1.0.int8.onnx --local-dir .
    huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX voices-v1.0.bin --local-dir .
else
    echo "✓ 使用 curl 下载"
    
    # 下载 ONNX 模型
    if [ ! -f "kokoro-v1.0.int8.onnx" ]; then
        echo "下载 kokoro-v1.0.int8.onnx (~300MB)..."
        curl -L -o kokoro-v1.0.int8.onnx \
            "https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/kokoro-v1.0.int8.onnx"
    else
        echo "✓ kokoro-v1.0.int8.onnx 已存在"
    fi
    
    # 下载语音文件
    if [ ! -f "voices-v1.0.bin" ]; then
        echo "下载 voices-v1.0.bin (~5MB)..."
        curl -L -o voices-v1.0.bin \
            "https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/voices-v1.0.bin"
    else
        echo "✓ voices-v1.0.bin 已存在"
    fi
fi

# 验证下载
echo ""
echo "📋 验证文件..."
if [ -f "kokoro-v1.0.int8.onnx" ] && [ -f "voices-v1.0.bin" ]; then
    ls -lh kokoro-v1.0.int8.onnx voices-v1.0.bin
    echo ""
    echo "✅ 模型下载完成！"
else
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi

echo ""
echo "下一步:"
echo "1. 运行 flutter pub get"
echo "2. 在 main.dart 中启用 Kokoro TTS"
echo "3. 运行应用测试"
