void relational(int? value) {
  if (value != null) print('not null');
}

void relationalNull(int? value) {
  if (value == null) print('null');
}

void wildcardNullCheck(int? value) {
  if (value != null) print('not null');
}

void binds(int? value) {
  if (value case final bound?) print(bound);
}

void typed(Object? value) {
  if (value case int _?) print('an int');
}

void guarded(int? value) {
  if (value case final bound? when bound > 0) print(bound);
}

void plain(int? value) {
  if (value != null) print('not null');
}
