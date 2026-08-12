import 'package:flutter/widgets.dart';

class Direct extends StatelessWidget {
  const Direct({super.key});

  @override
  Widget build(BuildContext context) {
    // expect_lint: avoid-recursive-widget-calls
    return Direct();
  }
}

class Nested extends StatelessWidget {
  const Nested({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      // expect_lint: avoid-recursive-widget-calls
      child: Nested(),
    );
  }
}

class Stateful extends StatefulWidget {
  const Stateful({super.key});

  @override
  State<Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<Stateful> {
  @override
  Widget build(BuildContext context) {
    // expect_lint: avoid-recursive-widget-calls
    return Stateful();
  }
}

class Fine extends StatelessWidget {
  const Fine({super.key});

  @override
  Widget build(BuildContext context) => const Text('leaf');
}

class Composes extends StatelessWidget {
  const Composes({super.key});

  @override
  Widget build(BuildContext context) => const Fine();
}
