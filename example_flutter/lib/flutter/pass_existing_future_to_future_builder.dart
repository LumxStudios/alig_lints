import 'package:flutter/widgets.dart';

Future<int> load() async {
  await Future<void>.delayed(.zero);

  return 1;
}

class Inline extends StatelessWidget {
  const Inline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      // expect_lint: pass-existing-future-to-future-builder
      future: load(),
      builder: (context, snapshot) => Text('${snapshot.data ?? 0}'),
    );
  }
}

class AlsoInline extends StatelessWidget {
  const AlsoInline({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      // expect_lint: pass-existing-future-to-future-builder
      future: Future<int>.value(1),
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
  late final Future<int> _pending;

  @override
  void initState() {
    super.initState();
    _pending = load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _pending,
      builder: (context, snapshot) => Text('${snapshot.data ?? 0}'),
    );
  }
}
