#!/bin/bash

# Kokoro TTS 模型下载脚本
# 用于下载必需的模型文件到 assets 目录

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 开始下载 Kokoro TTS 模型..."
echo "目录：$SCRIPT_DIR"

# 检查是否有 huggingface-cli
if command -v huggingface-cli &> /dev/null; then
    echo "✓ 使用 huggingface-cli 下载"
    huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX kokoro-v1.0.int8.onnx --local-dir .
    huggingface-cli download onnx-community/Kokoro-82M-v1.0-ONNX voices-v1.0.bin --local-dir .
else
    echo "✓ 使用 curl 下载"
    
    # 下载 ONNX 模型
    if [ ! -f "kokoro-v1.0.int8.onnx" ]; then
        echo "下载 kokoro-v1.0.int8.onnx (~80MB)..."
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
    echo ""
    echo "下一步:"
    echo "1. 运行 flutter pub get"
    echo "2. 在 main.dart 中启用 Kokoro TTS"
    echo "3. 运行应用测试"
else
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi
