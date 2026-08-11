void log(String message) {}

int compute() => 1;

// Looks like a block; actually builds a set and throws it away.
// expect_lint: avoid-misused-set-literals
void handler() => {
      log('started'),
      log('finished'),
    };

// expect_lint: avoid-misused-set-literals
void single() => {log('once')};

class Service {
  // expect_lint: avoid-misused-set-literals
  void onEvent() => {log('event')};
}

// A real block body.
void blockBody() {
  log('started');
  log('finished');
}

// The function genuinely returns a set.
Set<int> numbers() => {1, 2, 3};

Set<String> names() => {'a', 'b'};

// An iterable return type accepts a set too.
Iterable<int> iterable() => {1, 2};

// A map literal, not a set.
Map<String, int> byName() => {'a': 1};

// An expression body returning a value.
int value() => compute();

// A closure the built-in warning never examined.
void closure() {
  // expect_lint: avoid-misused-set-literals
  final void Function() callback = () => {log('done')};

  callback();
}
