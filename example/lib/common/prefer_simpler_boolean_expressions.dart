bool check() => true;

void main(List<String> args) {
  final flag = args.isEmpty;
  final other = args.length > 1;

  // expect_lint: prefer-simpler-boolean-expressions
  final orForm = flag ? true : other;

  // expect_lint: prefer-simpler-boolean-expressions
  final andForm = flag ? other : false;

  // expect_lint: prefer-simpler-boolean-expressions
  final negatedAnd = flag ? false : other;

  // expect_lint: prefer-simpler-boolean-expressions
  final negatedOr = flag ? other : true;

  // expect_lint: prefer-simpler-boolean-expressions
  final withCall = flag ? true : check();

  // Both branches are literals: avoid-unnecessary-conditionals' shape.
  // expect_lint: avoid-unnecessary-conditionals
  final bothLiterals = flag ? true : false;

  // Neither branch is a boolean literal.
  final realChoice = flag ? other : check();

  // Not a boolean conditional at all.
  final label = flag ? 'yes' : 'no';

  print([orForm, andForm, negatedAnd, negatedOr, withCall, bothLiterals,
      realChoice, label]);
}
