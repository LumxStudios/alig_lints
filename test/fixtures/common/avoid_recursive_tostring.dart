class Node {
  Node(this.label);

  final String label;

  @override
  String toString() {
    return 'Node($label, ${toString()})';
  }
}

class Direct {
  @override
  String toString() => 'Direct: $this';
}

class Fine {
  Fine(this.label);

  final String label;

  @override
  String toString() => 'Fine($label)';
}

class Delegates {
  @override
  String toString() => 'Delegates: ${super.toString()}';
}
