enum Status { active, paused, stopped }

Status byLiteralIndex() {
  return Status.values[0];
}

Status byComputedIndex(int offset) {
  return Status.values[offset];
}

Status byName() => Status.active;

void iterateAll() {
  for (final status in Status.values) {
    print(status);
  }
}

int positionOf(Status status) => status.index;

int firstOf(List<int> numbers) => numbers[0];
