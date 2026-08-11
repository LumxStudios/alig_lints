bool describe(int value, bool flag) {
  final isPositive = value > 0 ? true : false;
  final isNotPositive = value > 0 ? false : true;
  final neither = flag && value > 0 ? false : true;
  final negated = flag ? false : true;
  final label = value > 0 ? 'positive' : 'other';
  final mixed = value > 0 ? true : flag;

  print([isNotPositive, neither, negated, label, mixed]);

  return isPositive;
}
