void main(List<String> args) {
  final left = args.first;
  final right = args.last;
  final a = args.length;
  final b = args.length + 1;
  final x = a / 2;
  final y = b / 2;

  if (left.compareTo(right) == 0) print('equal strings');
  if (left.compareTo(right) != 0) print('different strings');
  if (0 == a.compareTo(b)) print('equal ints');
  if (left.compareTo(right) > 0) print('ordered');
  if (x.compareTo(y) == 0) print('double compare');
}
