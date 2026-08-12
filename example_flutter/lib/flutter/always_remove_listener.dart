import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  // expect_lint: dispose-fields
  final _notifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // expect_lint: always-remove-listener
    _notifier.addListener(_onChanged);
  }

  void _onChanged() {}

  @override
  Widget build(BuildContext context) => const Text('a');
}

class Balanced extends StatefulWidget {
  const Balanced({super.key});

  @override
  State<Balanced> createState() => _BalancedState();
}

class _BalancedState extends State<Balanced> {
  final _notifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    _notifier.dispose();
    super.dispose();
  }

  void _onChanged() {}

  @override
  Widget build(BuildContext context) => const Text('a');
}
