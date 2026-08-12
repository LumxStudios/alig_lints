// A note about what this file demonstrates.
// Nothing here is code, so nothing above is reported.

int compute() {
  return 2;
}

/// Documentation is never reported, even when it shows code:
/// final value = compute();
int documented() => compute();

void prose() {
  // The value is computed lazily, so this is cheap.
  // See the notes for why; the list is empty;
  // coverage:ignore-line
  print(compute());

}
