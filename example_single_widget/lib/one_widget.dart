import 'package:flutter/widgets.dart';

// expect_lint: avoid-unnecessary-stateful-widgets
class Only extends StatefulWidget {
  const Only({super.key});

  @override
  State<Only> createState() => _OnlyState();
}

// A State is not a widget, so this file still holds only one.
class _OnlyState extends State<Only> {
  @override
  Widget build(BuildContext context) => const Text('only');
}

// Neither is a plain helper class.
class Helper {
  const Helper();
}
