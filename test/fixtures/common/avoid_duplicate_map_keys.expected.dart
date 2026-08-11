void main() {
  final multiLine = <String, int>{
    'beta': 2,
    'alpha': 3,
  };

  final singleLine = <int, String>{2: 'two', 1: 'uno'};

  final fine = <String, int>{'a': 1, 'b': 2};

  print([multiLine, singleLine, fine]);
}
