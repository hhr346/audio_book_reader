import 'package:flutter/material.dart';

class FontSettingsScreen extends StatelessWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('字体设置')),
      body: const Center(child: Text('字体大小/粗细/行距调节')),
    );
  }
}
