void main() {
  final multiLine = <String, int>{
    'alpha': 1,
    'beta': 2,
    'alpha': 3,
  };

  final singleLine = <int, String>{1: 'one', 2: 'two', 1: 'uno'};

  final fine = <String, int>{'a': 1, 'b': 2};

  print([multiLine, singleLine, fine]);
}
