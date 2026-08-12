// expect_lint: prefer-public-exception-classes
class _HiddenException implements Exception {
  const _HiddenException(this.reason);

  final String reason;

  @override
  String toString() => 'HiddenException: $reason';
}

// expect_lint: prefer-public-exception-classes
class _HiddenError extends Error {
  @override
  String toString() => 'HiddenError';
}

class VisibleException implements Exception {
  const VisibleException(this.reason);

  final String reason;

  @override
  String toString() => 'VisibleException: $reason';
}

class _Helper {
  const _Helper();
}

void throwing() {
  throw _HiddenException('bad');
}

void alsoThrowing() {
  throw _HiddenError();
}

void helper() {
  print(const _Helper());
}
