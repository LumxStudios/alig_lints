import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid-missing-image-alt
        Image.asset('a.png'),
        // expect_lint: avoid-missing-image-alt
        Image.network('https://example.test/b.png'),

        Image.asset('c.png', semanticLabel: 'A chart of monthly totals'),
        Image.asset('d.png', excludeFromSemantics: true),
      ],
    );
  }
}
