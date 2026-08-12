abstract class Base {
  String render(String text, {int width = 80, bool bold = false});
}

class Matching extends Base {
  @override
  String render(String text, {int width = 80, bool bold = false}) => text;
}

class Diverging extends Base {
  @override
  String render(String text, {int width = 40, bool bold = false}) => text;
}

class NoDefault extends Base {
  @override
  String render(String text, {int width = 80, bool bold = true}) => text;
}
