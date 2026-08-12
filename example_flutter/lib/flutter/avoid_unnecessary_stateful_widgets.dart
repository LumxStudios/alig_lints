import 'package:flutter/widgets.dart';

// expect_lint: avoid-unnecessary-stateful-widgets
class Plain extends StatefulWidget {
  const Plain({super.key});

  @override
  State<Plain> createState() => _PlainState();
}

class _PlainState extends State<Plain> {
  @override
  Widget build(BuildContext context) => const Text('plain');
}

// Calls setState, so it has state to keep.
class Counting extends StatefulWidget {
  const Counting({super.key});

  @override
  State<Counting> createState() => _CountingState();
}

class _CountingState extends State<Counting> {
  int counter = 0;

  void bump() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}

// Overrides a lifecycle method, so it is doing something with the life cycle.
class Disposing extends StatefulWidget {
  const Disposing({super.key});

  @override
  State<Disposing> createState() => _DisposingState();
}

class _DisposingState extends State<Disposing> {
  @override
  void dispose() {
    debugPrint('gone');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('disposing');
}

class AlreadyStateless extends StatelessWidget {
  const AlreadyStateless({super.key});

  @override
  Widget build(BuildContext context) => const Text('stateless');
}
