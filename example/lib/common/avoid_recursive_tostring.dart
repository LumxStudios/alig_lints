class Node {
  const Node(this.label);

  final String label;

  @override
  String toString() {
    // expect_lint: avoid-recursive-tostring
    return 'Node($label, ${toString()})';
  }
}

class Direct {
  @override
  // expect_lint: avoid-recursive-tostring
  String toString() => 'Direct: $this';
}

class Fine {
  const Fine(this.label);

  final String label;

  @override
  String toString() => 'Fine($label)';
}

class Delegates {
  @override
  String toString() => 'Delegates: ${super.toString()}';
}
