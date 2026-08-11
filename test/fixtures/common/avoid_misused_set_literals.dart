void log(String message) {}

int compute() => 1;

void handler() => {
      log('started'),
      log('finished'),
    };

void single() => {log('once')};

class Service {
  void onEvent() => {log('event')};
}

void blockBody() {
  log('started');
}

Set<int> numbers() => {1, 2, 3};

Iterable<int> iterable() => {1, 2};

Map<String, int> byName() => {'a': 1};

int value() => compute();

void closure() {
  final void Function() callback = () => {log('done')};

  callback();
}
