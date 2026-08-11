import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  int counter = 0;

  void bad() {
    // expect_lint: avoid-empty-setstate
    setState(() {});
  }

  void alsoBad() {
    // expect_lint: avoid-empty-setstate
    setState(() {
      // Nothing here.
    });
  }

  void good() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}
