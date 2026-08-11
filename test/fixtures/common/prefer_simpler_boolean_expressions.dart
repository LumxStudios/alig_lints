bool check() => true;

void main(List<String> args) {
  final flag = args.isEmpty;
  final other = args.length > 1;

  final orForm = flag ? true : other;
  final andForm = flag ? other : false;
  final negatedAnd = flag ? false : other;
  final negatedOr = flag ? other : true;
  final withCall = flag ? true : check();
  final bothLiterals = flag ? true : false;
  final realChoice = flag ? other : check();
  final label = flag ? 'yes' : 'no';

  print([orForm, andForm, negatedAnd, negatedOr, withCall, bothLiterals,
      realChoice, label]);
}
