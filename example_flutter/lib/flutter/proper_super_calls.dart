import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  int counter = 0;

  @override
  void initState() {
    counter = 1;
    // expect_lint: proper-super-calls
    super.initState();
  }

  @override
  void dispose() {
    // expect_lint: proper-super-calls
    super.dispose();
    counter = 0;
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}

class Correct extends StatefulWidget {
  const Correct({super.key});

  @override
  State<Correct> createState() => _CorrectState();
}

class _CorrectState extends State<Correct> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    counter = 1;
  }

  @override
  void dispose() {
    counter = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}
