List<int> listSpread(List<int>? values) {
  return [if (values != null) ...values];
}

Set<int> setSpread(Set<int>? values) {
  return {if (values != null) ...values};
}

Map<String, int> mapSpread(Map<String, int>? values) {
  return {if (values != null) ...values};
}

List<int> withBang(List<int>? values) {
  return [if (values != null) ...values!];
}

List<int> withElse(List<int>? values, List<int> fallback) =>
    [if (values != null) ...values else ...fallback];

List<int> different(List<int>? values, List<int> others) =>
    [if (values != null) ...others];

List<int> plain(List<int> values) => [...values];
