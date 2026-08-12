enum Status { active, paused }

enum Level { low, high }

class Job {
  const Job({required this.status, this.level = Level.low});

  final Status status;
  final Level level;
}

void argument() {
  // expect_lint: prefer-shorthands-with-enums, avoid-unused-instances
  Job(status: Status.active);
}

void assignment() {
  // expect_lint: prefer-shorthands-with-enums
  Status current = Status.paused;

  print(current);
}

void comparison(Status status) {
  // expect_lint: prefer-shorthands-with-enums
  if (status == Status.active) print('active');
}

String pattern(Status status) => switch (status) {
      // expect_lint: prefer-shorthands-with-enums
      Status.active => 'active',
      // expect_lint: prefer-shorthands-with-enums
      Status.paused => 'paused',
    };

// Already shorthand.
void already() {
  // expect_lint: avoid-unused-instances
  Job(status: .active);
}

// No context type to resolve against.
void noContext() {
  final value = Status.active;

  print(value);
}

// A different enum than the context expects would not resolve.
void printsName() {
  print(Status.active.name);
}
