List<int> listElement(int? value) {
  return [if (value != null) value];
}

Set<int> setElement(int? value) {
  return {if (value != null) value};
}

Map<String, int> mapValue(int? value) {
  return {if (value != null) 'total': value};
}

List<int> withBang(int? value) {
  return [if (value != null) value!];
}

List<int> withElse(int? value) => [if (value != null) value else 0];

List<int> different(int? value, int other) => [if (value != null) other];

List<int> notNullCheck(bool flag, int value) => [if (flag) value];

List<int> plain(int value) => [value];
