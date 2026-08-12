class Resource {
  void dispose() {}
}

class Owner {
  final Resource forgotten = Resource();
  final Resource released = Resource();

  void dispose() {
    released.dispose();
  }
}

class Complete {
  final Resource first = Resource();
  final Resource second = Resource();

  void dispose() {
    first.dispose();
    second.dispose();
  }
}

// No teardown method at all, which is a design choice rather than a defect.
class NoTeardown {
  final Resource resource = Resource();
}

class Closer {
  final Resource resource = Resource();

  void close() {
    resource.dispose();
  }
}
