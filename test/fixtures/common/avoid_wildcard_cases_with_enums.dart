enum Status { active, paused, stopped }

String describeWithWildcard(Status status) {
  switch (status) {
    case Status.active:
      return 'active';
    case _:
      return 'other';
  }
}

String describeWithDefault(Status status) {
  switch (status) {
    case Status.active:
      return 'active';
    default:
      return 'other';
  }
}

String describeExpression(Status status) => switch (status) {
      Status.active => 'active',
      _ => 'other',
    };

String describeNullable(Status? status) => switch (status) {
      Status.active => 'active',
      null => 'none',
      _ => 'other',
    };

String exhaustive(Status status) => switch (status) {
      Status.active => 'active',
      Status.paused => 'paused',
      Status.stopped => 'stopped',
    };

String describeInt(int value) => switch (value) {
      1 => 'one',
      _ => 'other',
    };
