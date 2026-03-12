#!/bin/bash
# audio_book_reader - 快速测试脚本

set -e

echo "📱 Audio Book Reader - 测试脚本"
echo "================================"
echo ""

cd /Users/hhr/Desktop/audio_book_reader

# 检查模型文件
echo "📦 检查 Kokoro 模型文件..."
if [ -f "assets/kokoro-v1.0.int8.onnx" ] && [ -f "assets/voices-v1.0.bin" ]; then
    echo "✅ Kokoro 模型文件存在"
    ls -lh assets/*.onnx assets/*.bin
else
    echo "⚠️  Kokoro 模型文件缺失"
    echo ""
    echo "请运行以下命令下载:"
    echo "  cd assets && bash download_models.sh"
    echo ""
    echo "或者手动下载:"
    echo "  https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX"
    echo ""
fi

echo ""
echo "🔧 检查依赖..."
flutter pub get

echo ""
echo "🏗️  编译应用..."
flutter build ios --simulator --no-codesign

echo ""
echo "✅ 编译完成！"
echo ""
echo "下一步:"
echo "1. 打开 Xcode: open ios/Runner.xcworkspace"
echo "2. 选择模拟器"
echo "3. 运行应用"
echo ""
echo "或者直接使用:"
echo "  flutter run"
echo ""
