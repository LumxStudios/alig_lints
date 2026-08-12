import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('a'),
        // expect_lint: prefer-spacing
        const SizedBox(height: 8),
        const Text('b'),
        // expect_lint: prefer-spacing
        const SizedBox(height: 8),
        const Text('c'),
      ],
    );
  }
}

class Rows extends StatelessWidget {
  const Rows({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('a'),
        // expect_lint: prefer-spacing
        const SizedBox(width: 12),
        const Text('b'),
      ],
    );
  }
}

class Spaced extends StatelessWidget {
  const Spaced({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: const [Text('a'), Text('b')],
    );
  }
}

class Edges extends StatelessWidget {
  const Edges({super.key});

  @override
  Widget build(BuildContext context) {
    // A box at either end is padding, not a gap between children.
    return Column(
      children: const [
        SizedBox(height: 8),
        Text('a'),
        Text('b'),
        SizedBox(height: 8),
      ],
    );
  }
}

class Sized extends StatelessWidget {
  const Sized({super.key});

  @override
  Widget build(BuildContext context) {
    // A box with a child is a widget, not a gap.
    return Column(
      children: const [
        Text('a'),
        SizedBox(height: 8, child: Text('inside')),
        Text('b'),
      ],
    );
  }
}
