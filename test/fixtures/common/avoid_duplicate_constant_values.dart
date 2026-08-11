class Timeouts {
  static const short = 5;
  static const medium = 10;
  static const quick = 5;
}

enum Priority {
  low(1),
  high(2),
  urgent(2);

  const Priority(this.weight);

  final int weight;
}

class Distinct {
  static const a = 1;
  static const b = 'a';
  static const c = true;
}
