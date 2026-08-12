class Size {
  Size(this._width, this._height);

  final int _width;
  int _height;

  // expect_lint: match-getter-setter-field-names
  int get width => _height;

  int get height => _height;

  // expect_lint: match-getter-setter-field-names
  set width(int value) => _height = value;

  set height(int value) => _height = value;

  // Computing from several fields is not a mismatch.
  int get area => _width * _height;

  // Nothing to match against.
  int get doubled => 2 * 2;
}
