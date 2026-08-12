import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  int counter = 0;

  Future<void> bad() async {
    await Future<void>.delayed(.zero);
    setState(() {
      // expect_lint: avoid-mounted-in-setstate
      if (mounted) counter++;
    });
  }

  Future<void> alsoBad() async {
    await Future<void>.delayed(.zero);
    setState(() {
      // expect_lint: avoid-mounted-in-setstate
      if (!mounted) return;
      counter++;
    });
  }

  Future<void> good() async {
    await Future<void>.delayed(.zero);
    if (!mounted) return;
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}
