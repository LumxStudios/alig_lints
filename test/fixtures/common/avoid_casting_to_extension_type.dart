extension type Meters(int value) {}

extension type Label.wrap(String text) {}

extension type Boxed<T>(T value) {}

void casts(Object object, int number, dynamic anything) {
  print(number as Meters);
  print(object as Meters);
  print(anything as Label);
  print(number as Boxed<int>);

  final meters = Meters(3);
  print(meters as Object);
  print(object as int);
}
