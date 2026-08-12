import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inside a Flex, which is what Flexible needs.
        const Flexible(child: Text('a')),
        const Expanded(child: Text('b')),
        Container(
          // expect_lint: avoid-flexible-outside-flex
          child: const Flexible(child: Text('c')),
        ),
        Center(
          // expect_lint: avoid-flexible-outside-flex
          child: const Expanded(child: Text('d')),
        ),
      ],
    );
  }
}

class Rows extends StatelessWidget {
  const Rows({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: const [Expanded(child: Text('a'))],
      );
}

class Standalone extends StatelessWidget {
  const Standalone({super.key});

  // No enclosing widget here, so what it ends up inside is not visible.
  @override
  Widget build(BuildContext context) => const Flexible(child: Text('a'));
}
