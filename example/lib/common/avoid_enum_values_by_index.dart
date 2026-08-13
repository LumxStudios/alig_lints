enum Status { active, paused, stopped }

Status byLiteralIndex() {
  // Reordering the enum silently changes what this returns.
  // expect_lint: avoid-enum-values-by-index
  return Status.values[0];
}

Status byComputedIndex(int offset) {
  // expect_lint: avoid-enum-values-by-index
  return Status.values[offset];
}

Status byIndexOfAnother(Status other) {
  // expect_lint: avoid-enum-values-by-index
  return Status.values[other.index];
}

// Naming the value survives reordering.
Status byName() => Status.active;

// Iterating every value does not depend on order.
void iterateAll() {
  for (final status in Status.values) {
    print(status);
  }
}

// Reading the index is not the same as indexing by it.
int positionOf(Status status) => status.index;

// An ordinary list is indexed by position by design.
int firstOf(List<int> numbers) => numbers[0];
