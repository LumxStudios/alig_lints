import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  // expect_lint: dispose-fields
  final _forgotten = ValueNotifier<int>(0);
  final _disposed = ValueNotifier<int>(0);

  @override
  void dispose() {
    _disposed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('${_forgotten.value}');
}

class NoDispose extends StatefulWidget {
  const NoDispose({super.key});

  @override
  State<NoDispose> createState() => _NoDisposeState();
}

class _NoDisposeState extends State<NoDispose> {
  // The framework always calls dispose, so its absence is the leak.
  // expect_lint: dispose-fields
  final _notifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) => Text('${_notifier.value}');
}

class Cascaded extends StatefulWidget {
  const Cascaded({super.key});

  @override
  State<Cascaded> createState() => _CascadedState();
}

class _CascadedState extends State<Cascaded> {
  final _notifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _notifier..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('${_notifier.value}');
}
