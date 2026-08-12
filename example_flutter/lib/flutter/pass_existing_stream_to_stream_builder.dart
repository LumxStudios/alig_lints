import 'dart:async';

import 'package:flutter/widgets.dart';

Stream<int> ticks() => .periodic(const Duration(seconds: 1), (i) => i);

class Inline extends StatelessWidget {
  const Inline({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      // expect_lint: pass-existing-stream-to-stream-builder
      stream: ticks(),
      builder: (context, snapshot) => Text('${snapshot.data ?? 0}'),
    );
  }
}

class Kept extends StatefulWidget {
  const Kept({super.key});

  @override
  State<Kept> createState() => _KeptState();
}

class _KeptState extends State<Kept> {
  late final Stream<int> _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = ticks();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticks,
      builder: (context, snapshot) => Text('${snapshot.data ?? 0}'),
    );
  }
}
