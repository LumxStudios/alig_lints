import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    // expect_lint: prefer-dedicated-media-query-methods
    final size = MediaQuery.of(context).size;
    // expect_lint: prefer-dedicated-media-query-methods
    final padding = MediaQuery.of(context).padding;
    // expect_lint: prefer-dedicated-media-query-methods
    final ratio = MediaQuery.maybeOf(context)?.devicePixelRatio;

    final already = MediaQuery.sizeOf(context);
    final data = MediaQuery.of(context);

    return Text('$size $padding ${ratio ?? 0} $already ${data.orientation}');
  }
}
