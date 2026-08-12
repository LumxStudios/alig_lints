import 'package:flutter/material.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid-undisposed-instances
        TextField(controller: TextEditingController()),
        ValueListenableBuilder<int>(
          // expect_lint: avoid-undisposed-instances
          valueListenable: ValueNotifier<int>(0),
          builder: (context, value, child) => Text('$value'),
        ),
      ],
    );
  }
}

class Kept extends StatefulWidget {
  const Kept({super.key});

  @override
  State<Kept> createState() => _KeptState();
}

class _KeptState extends State<Kept> {
  final _controller = TextEditingController();
  late final ValueNotifier<int> _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ValueNotifier<int>(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: _controller);
}

// Handing one back makes it the caller's to dispose.
TextEditingController make() => TextEditingController();
