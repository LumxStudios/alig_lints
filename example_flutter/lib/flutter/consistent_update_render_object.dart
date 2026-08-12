import 'package:flutter/widgets.dart';

class _Box extends RenderBox {
  double width = 0;
  double height = 0;
}

class Complete extends SingleChildRenderObjectWidget {
  const Complete({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _Box()..width = width
        ..height = height;

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _Box)
      ..width = width
      ..height = height;
  }
}

class MissingField extends SingleChildRenderObjectWidget {
  const MissingField({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _Box()..width = width
        ..height = height;

  @override
  // expect_lint: consistent-update-render-object
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _Box).width = width;
  }
}

class MissingMethod extends SingleChildRenderObjectWidget {
  const MissingMethod({super.key, required this.width});

  final double width;

  @override
  // expect_lint: consistent-update-render-object
  RenderObject createRenderObject(BuildContext context) =>
      _Box()..width = width;
}
