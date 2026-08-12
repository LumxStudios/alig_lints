import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  int counter = 0;

  Future<void> unguarded() async {
    await Future<void>.delayed(.zero);
    // expect_lint: use-setstate-synchronously
    setState(() {
      counter++;
    });
  }

  Future<void> guardedByReturn() async {
    await Future<void>.delayed(.zero);
    if (!mounted) return;
    setState(() {
      counter++;
    });
  }

  Future<void> guardedByIf() async {
    await Future<void>.delayed(.zero);
    if (mounted) {
      setState(() {
        counter++;
      });
    }
  }

  Future<void> beforeTheAwait() async {
    setState(() {
      counter++;
    });
    await Future<void>.delayed(.zero);
  }

  void synchronous() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}
