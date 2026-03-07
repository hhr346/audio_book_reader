import 'package:flutter/material.dart';

class NightModeScreen extends StatelessWidget {
  const NightModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('夜间模式')),
      body: const Center(child: Text('夜间模式设置页面')),
    );
  }
}
