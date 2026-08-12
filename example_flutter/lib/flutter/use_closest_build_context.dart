import 'package:flutter/widgets.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        // expect_lint: use-closest-build-context
        return Text(MediaQuery.sizeOf(context).width.toString());
      },
    );
  }
}

class Correct extends StatelessWidget {
  const Correct({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (innerContext) {
        return Text(MediaQuery.sizeOf(innerContext).width.toString());
      },
    );
  }
}

class NoInnerContext extends StatelessWidget {
  const NoInnerContext({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(MediaQuery.sizeOf(context).width.toString());
  }
}
