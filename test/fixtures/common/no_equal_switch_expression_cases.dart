String classify(int value) => switch (value) {
      1 => 'small',
      2 => 'medium',
      3 => 'small',
      _ => 'other',
    };

int weigh(String name) => switch (name) {
      'a' => name.length * 2,
      'b' => name.length * 3,
      'c' => name.length * 2,
      _ => 0,
    };

String shared(int value) => switch (value) {
      1 || 2 => 'low',
      3 => 'high',
      _ => 'other',
    };

String matchesWildcard(int value) => switch (value) {
      1 => 'one',
      _ => 'one',
    };
