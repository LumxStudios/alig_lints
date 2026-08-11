// This file demonstrates a different rule; its enum and static-field references
// are written in full for clarity rather than as shorthands.
// ignore_for_file: prefer-shorthands-with-enums
// ignore_for_file: prefer-shorthands-with-static-fields

enum Color { red, green }

class Size {
  const Size(this.value);

  static const small = Size(1);

  final int value;
}

class Style {
  const Style(this.color, {required this.size});

  static Style of(Color color, {required Size size}) => Style(color, size: size);

  final Color color;
  final Size size;
}

class Theme {
  const Theme(this.style);

  static Theme from(Style style) => Theme(style);

  final Style style;
}

Theme nested() =>
    // expect_lint: avoid-nested-shorthands
    .from(.of(.red, size: .small));

Theme constructorNested() =>
    // expect_lint: avoid-nested-shorthands
    .new(.of(.red, size: .small));

// One level of shorthand is the point of the feature.
Style flat() => .of(Color.red, size: Size.small);

Theme explicitInner() => .from(Style.of(Color.red, size: Size.small));

Color plain() => .red;
