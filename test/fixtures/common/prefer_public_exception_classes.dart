class _HiddenException implements Exception {
  _HiddenException(this.reason);

  final String reason;

  @override
  String toString() => 'HiddenException: $reason';
}

class _HiddenError extends Error {
  @override
  String toString() => 'HiddenError';
}

class VisibleException implements Exception {
  VisibleException(this.reason);

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
