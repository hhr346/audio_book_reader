// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:audio_book_reader/main.dart';
import 'package:audio_book_reader/services/storage_service.dart';

void main() {
  testWidgets('书架页面加载测试', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StorageService(),
        child: const AudioBookApp(),
      ),
    );

    // 验证书架页面加载
    expect(find.text('📚 有声书架'), findsOneWidget);
    
    // 验证空状态提示
    expect(find.text('书架空空如也'), findsOneWidget);
  });
}
