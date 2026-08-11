// The name is documentation only: the field is still reached as `$1`.
// expect_lint: avoid-redundant-positional-field-name
(int count, String) singleNamed() => (1, 'a');

(
  // expect_lint: avoid-redundant-positional-field-name
  int count,
  // expect_lint: avoid-redundant-positional-field-name
  String label,
) bothNamed() => (1, 'a');

// Positional fields without names.
(int, String) plain() => (1, 'a');

// Named fields really are named, and keep their names.
({int count, String label}) named() => (count: 1, label: 'a');

// A mix: only the positional half is reported.
(
  // expect_lint: avoid-redundant-positional-field-name
  int count,
  {
  String label,
}) mixed() => (1, label: 'a');
