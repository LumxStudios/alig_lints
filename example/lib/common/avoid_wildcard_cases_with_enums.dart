// This file demonstrates a different rule; its enum references are written in
// full for clarity rather than as shorthands.
// ignore_for_file: prefer-shorthands-with-enums

enum Status { active, paused, stopped }

String describeWithWildcard(Status status) {
  switch (status) {
    case Status.active:
      return 'active';
    // expect_lint: avoid-wildcard-cases-with-enums
    case _:
      return 'other';
  }
}

String describeWithDefault(Status status) {
  switch (status) {
    case Status.active:
      return 'active';
    // expect_lint: avoid-wildcard-cases-with-enums
    default:
      return 'other';
  }
}

String describeExpression(Status status) => switch (status) {
      Status.active => 'active',
      // expect_lint: avoid-wildcard-cases-with-enums
      _ => 'other',
    };

String describeNullable(Status? status) => switch (status) {
      Status.active => 'active',
      null => 'none',
      // expect_lint: avoid-wildcard-cases-with-enums
      _ => 'other',
    };

// Listing every value keeps the compiler checking this switch.
String exhaustive(Status status) => switch (status) {
      Status.active => 'active',
      Status.paused => 'paused',
      Status.stopped => 'stopped',
    };

String exhaustiveStatement(Status status) {
  switch (status) {
    case Status.active:
      return 'active';
    case Status.paused:
      return 'paused';
    case Status.stopped:
      return 'stopped';
  }
}

// Not an enum, so a wildcard is the only way to finish.
String describeInt(int value) => switch (value) {
      1 => 'one',
      _ => 'other',
    };
