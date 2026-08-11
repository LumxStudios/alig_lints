class Builder {
  int width = 0;
  int height = 0;

  void grow(int by) {}
}

void main() {
  Builder()
    ..grow(1);

  Builder()
    ..width = 1
    ..height = 2;

  Builder()
    ..grow(1)
    ..grow(2);
}
