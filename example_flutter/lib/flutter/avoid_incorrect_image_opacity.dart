import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid-incorrect-image-opacity
        Opacity(
          opacity: 0.5,
          child: Image.asset('a.png', semanticLabel: 'A logo'),
        ),
        // expect_lint: avoid-incorrect-image-opacity
        Opacity(
          opacity: 0.5,
          child: Image.network(
            'https://example.test/b.png',
            semanticLabel: 'A banner',
          ),
        ),

        // Image carries the opacity itself, with no extra layer.
        Image.asset(
          'c.png',
          semanticLabel: 'A chart',
          opacity: const AlwaysStoppedAnimation(0.5),
        ),

        // Something other than an Image really does need the layer.
        Opacity(
          opacity: 0.5,
          child: Container(),
        ),
      ],
    );
  }
}
