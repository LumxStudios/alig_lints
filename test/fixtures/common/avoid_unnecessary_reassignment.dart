int compute() => 1;

void immediate() {
  var value = 1;
  value = 2;

  print(value);
}

void withUnrelatedStatementBetween() {
  var value = 1;
  print('unrelated');
  value = 2;

  print(value);
}

void initialValueIsUsed() {
  var value = 1;
  print(value);
  value = 2;

  print(value);
}

void buildsOnInitialValue() {
  var value = 1;
  value = value + 1;

  print(value);
}

void compoundAssignment() {
  var value = 1;
  value += 1;

  print(value);
}

void conditionalReassignment(bool flag) {
  var value = 1;
  if (flag) {
    value = 2;
  }

  print(value);
}

void reassignmentAfterAssignment() {
  var value = 1;
  print(value);

  value = compute();
  value = 3;

  print(value);
}
