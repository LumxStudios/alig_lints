int? find(bool present) => present ? 1 : null;

int addition(int? value, int base) {
  // Parses as value ?? (base + 1), which is easy to read the other way round.
  // expect_lint: prefer-parentheses-with-if-null
  return value ?? base + 1;
}

bool comparison(bool? flag, int count) {
  // expect_lint: prefer-parentheses-with-if-null
  return flag ?? count > 0;
}

bool logical(bool? flag, bool first, bool second) {
  // expect_lint: prefer-parentheses-with-if-null
  return flag ?? first && second;
}

// Parenthesised, so the grouping is stated.
int explicit(int? value, int base) => value ?? (base + 1);

// A chain of ?? is not surprising.
int chained(int? first, int? second) => first ?? second ?? 0;

// A single operand needs no parentheses.
int simple(int? value, int fallback) => value ?? fallback;

int fromCall(int fallback) => find(false) ?? fallback;
