import 'package:flutter/rendering.dart';

class Guarded extends RenderBox {
  double _width = 0;

  set width(double value) {
    if (_width == value) return;
    _width = value;
    markNeedsLayout();
  }
}

class GuardedWithBlock extends RenderBox {
  double _height = 0;

  set height(double value) {
    if (_height != value) {
      _height = value;
      markNeedsLayout();
    }
  }
}

class Unguarded extends RenderBox {
  double _width = 0;

  // expect_lint: check-for-equals-in-render-object-setters
  set width(double value) {
    _width = value;
    markNeedsLayout();
  }
}

class AlsoUnguarded extends RenderBox {
  Color _colour = const Color(0xFF000000);

  // expect_lint: check-for-equals-in-render-object-setters
  set colour(Color value) {
    _colour = value;
    markNeedsPaint();
  }
}

// Not a RenderObject, so a plain setter is fine.
class Holder {
  double _width = 0;

  set width(double value) {
    _width = value;
  }
}
