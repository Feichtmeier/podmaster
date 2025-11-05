import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.title});

  final Widget? title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: title ?? const Text('')),
    body: const Center(child: CircularProgressIndicator.adaptive()),
  );
}
