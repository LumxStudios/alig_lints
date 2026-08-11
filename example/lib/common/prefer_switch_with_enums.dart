// This file demonstrates a different rule; its enum references are written in
// full for clarity rather than as shorthands.
// ignore_for_file: prefer-shorthands-with-enums

enum Status { active, paused, stopped }

String twoBranches(Status status) {
  // expect_lint: prefer-switch-with-enums
  if (status == Status.active) {
    return 'active';
  } else if (status == Status.paused) {
    return 'paused';
  }

  return 'other';
}

String threeBranches(Status status) {
  // expect_lint: prefer-switch-with-enums
  if (status == Status.active) {
    return 'active';
  } else if (status == Status.paused) {
    return 'paused';
  } else if (status == Status.stopped) {
    return 'stopped';
  }

  return 'unknown';
}

// A single comparison reads fine as an if.
String single(Status status) {
  if (status == Status.active) {
    return 'active';
  }

  return 'other';
}

// The chain tests different things, so a switch would not fit.
String mixed(Status status, bool flag) {
  if (status == Status.active) {
    return 'active';
  } else if (flag) {
    return 'flagged';
  }

  return 'other';
}

// Different subjects.
String twoSubjects(Status first, Status second) {
  if (first == Status.active) {
    return 'first active';
  } else if (second == Status.paused) {
    return 'second paused';
  }

  return 'other';
}

// Not an enum.
String notEnum(int value) {
  if (value == 1) {
    return 'one';
  } else if (value == 2) {
    return 'two';
  }

  return 'other';
}
