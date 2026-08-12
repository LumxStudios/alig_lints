import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  void handle() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid-unnecessary-gesture-detector
        GestureDetector(child: const Text('a')),
        // expect_lint: avoid-unnecessary-gesture-detector
        GestureDetector(
          behavior: .opaque,
          child: const Text('b'),
        ),
        GestureDetector(
          onTap: handle,
          child: const Text('c'),
        ),
        GestureDetector(
          onLongPress: handle,
          child: const Text('d'),
        ),
      ],
    );
  }
}
