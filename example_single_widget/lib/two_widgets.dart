import 'package:flutter/widgets.dart';

class First extends StatelessWidget {
  const First({super.key});

  @override
  Widget build(BuildContext context) => const Text('first');
}

// expect_lint: prefer-single-widget-per-file
class Second extends StatelessWidget {
  const Second({super.key});

  @override
  Widget build(BuildContext context) => const Text('second');
}

// expect_lint: prefer-single-widget-per-file
class Third extends StatelessWidget {
  const Third({super.key});

  @override
  Widget build(BuildContext context) => const Text('third');
}
