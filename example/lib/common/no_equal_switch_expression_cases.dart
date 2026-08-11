String classify(int value) => switch (value) {
      1 => 'small',
      2 => 'medium',
      // expect_lint: no-equal-switch-expression-cases
      3 => 'small',
      _ => 'other',
    };

int weigh(String name) => switch (name) {
      'a' => name.length * 2,
      'b' => name.length * 3,
      // expect_lint: no-equal-switch-expression-cases
      'c' => name.length * 2,
      _ => 0,
    };

// Cases already sharing one body via a logical-or pattern are correct.
String shared(int value) => switch (value) {
      1 || 2 => 'low',
      3 => 'high',
      _ => 'other',
    };

// A wildcard whose body repeats a case is reported too: that case is redundant.
String matchesWildcard(int value) => switch (value) {
      1 => 'one',
      // expect_lint: no-equal-switch-expression-cases
      _ => 'one',
    };
