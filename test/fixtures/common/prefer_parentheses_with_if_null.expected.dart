int? find(bool present) => present ? 1 : null;

int addition(int? value, int base) {
  return value ?? (base + 1);
}

bool comparison(bool? flag, int count) {
  return flag ?? (count > 0);
}

int explicit(int? value, int base) => value ?? (base + 1);

int chained(int? first, int? second) => first ?? second ?? 0;

int simple(int? value, int fallback) => value ?? fallback;

int fromCall(int fallback) => find(false) ?? fallback;
