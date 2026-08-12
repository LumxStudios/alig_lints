import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  _SampleState() {
    // expect_lint: avoid-state-constructors
    counter = 1;
  }

  int counter = 0;

  @override
  Widget build(BuildContext context) => Text('$counter');
}

class Empty extends StatefulWidget {
  const Empty({super.key});

  @override
  State<Empty> createState() => _EmptyState();
}

class _EmptyState extends State<Empty> {
  _EmptyState();

  @override
  Widget build(BuildContext context) => const Text('empty');
}

class Initialised extends StatefulWidget {
  const Initialised({super.key});

  @override
  State<Initialised> createState() => _InitialisedState();
}

class _InitialisedState extends State<Initialised> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    counter = 1;
  }

  @override
  Widget build(BuildContext context) => Text('$counter');
}

// A plain class with a constructor body is not a State.
class Plain {
  Plain() {
    value = 1;
  }

  int value = 0;
}
