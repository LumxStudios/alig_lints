import 'package:flutter/widgets.dart';

class Sample extends StatefulWidget {
  const Sample({super.key, this.value = 0});

  final int value;

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    // expect_lint: avoid-unnecessary-setstate
    setState(() {
      counter = widget.value;
    });
  }

  @override
  void didUpdateWidget(Sample oldWidget) {
    super.didUpdateWidget(oldWidget);
    // expect_lint: avoid-unnecessary-setstate
    setState(() {
      counter = widget.value;
    });
  }

  void refresh() {
    // expect_lint: avoid-unnecessary-setstate
    setState(() {
      counter = widget.value;
    });
  }

  void onTap() {
    setState(() {
      counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    refresh();

    // expect_lint: avoid-unnecessary-setstate
    setState(() {
      counter = widget.value;
    });

    return Text('$counter');
  }
}
