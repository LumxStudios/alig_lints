List<int> listSpread(List<int>? values) {
  // expect_lint: prefer-null-aware-spread
  return [if (values != null) ...values];
}

Set<int> setSpread(Set<int>? values) {
  // expect_lint: prefer-null-aware-spread
  return {if (values != null) ...values};
}

Map<String, int> mapSpread(Map<String, int>? values) {
  // expect_lint: prefer-null-aware-spread
  return {if (values != null) ...values};
}

List<int> withBang(List<int>? values) {
  // expect_lint: prefer-null-aware-spread
  return [if (values != null) ...values!];
}

// An else branch cannot be written as ...?
List<int> withElse(List<int>? values, List<int> fallback) =>
    [if (values != null) ...values else ...fallback];

// Spreading something other than the tested value.
List<int> different(List<int>? values, List<int> others) =>
    [if (values != null) ...others];

// Already null-aware.
List<int> already(List<int>? values) => [...?values];

// A plain spread.
List<int> plain(List<int> values) => [...values];
