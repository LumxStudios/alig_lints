void relational(int? value) {
  // expect_lint: prefer-simpler-patterns-null-check
  if (value case != null) print('not null');
}

void relationalNull(int? value) {
  // expect_lint: prefer-simpler-patterns-null-check
  if (value case == null) print('null');
}

void wildcardNullCheck(int? value) {
  // expect_lint: prefer-simpler-patterns-null-check
  if (value case _?) print('not null');
}

// The binding is the point: it names the promoted value.
void binds(int? value) {
  if (value case final bound?) print(bound);
}

// A type test, not just a null check.
void typed(Object? value) {
  if (value case int _?) print('an int');
}

// A guard needs the pattern form.
void guarded(int? value) {
  if (value case final bound? when bound > 0) print(bound);
}

// Already a plain comparison.
void plain(int? value) {
  if (value != null) print('not null');
}
