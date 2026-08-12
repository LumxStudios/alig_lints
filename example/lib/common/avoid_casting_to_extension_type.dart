extension type Meters(int _value) {}

extension type Label.wrap(String _text) {}

extension type Boxed<T>(T _value) {}

// expect_lint: avoid-dynamic
void casts(Object object, int number, dynamic anything) {
  // expect_lint: avoid-casting-to-extension-type
  print(number as Meters);
  // expect_lint: avoid-casting-to-extension-type
  print(object as Meters);
  // expect_lint: avoid-casting-to-extension-type
  print(anything as Label);
  // expect_lint: avoid-casting-to-extension-type
  print(number as Boxed<int>);

  // Casting away from an extension type is checked normally.
  final meters = Meters(3);
  print(meters as Object);
  print(object as int);
}
