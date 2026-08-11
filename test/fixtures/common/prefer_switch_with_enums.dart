enum Status { active, paused, stopped }

String twoBranches(Status status) {
  if (status == Status.active) {
    return 'active';
  } else if (status == Status.paused) {
    return 'paused';
  }

  return 'other';
}

String single(Status status) {
  if (status == Status.active) {
    return 'active';
  }

  return 'other';
}

String mixed(Status status, bool flag) {
  if (status == Status.active) {
    return 'active';
  } else if (flag) {
    return 'flagged';
  }

  return 'other';
}

String twoSubjects(Status first, Status second) {
  if (first == Status.active) {
    return 'first active';
  } else if (second == Status.paused) {
    return 'second paused';
  }

  return 'other';
}

String notEnum(int value) {
  if (value == 1) {
    return 'one';
  } else if (value == 2) {
    return 'two';
  }

  return 'other';
}
