void risky() {}

void run(bool flag) {
  if (flag) {}

  if (flag) {
    print('then');
  } else {}

  while (flag) {}

  for (var index = 0; index < 3; index++) {}

  do {} while (flag);

  try {
    risky();
  } finally {}

  {}

  try {
    risky();
  } catch (e) {}

  if (flag) {
    print('ok');
  }
}

void noop() {}

class Service {
  Service() {}

  void onEvent() {}
}
