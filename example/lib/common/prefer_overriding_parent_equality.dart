class Base {
  const Base(this.id);

  final int id;

  @override
  bool operator ==(Object other) => other is Base && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// expect_lint: prefer-overriding-parent-equality
class Child extends Base {
  const Child(super.id, this.label);

  final String label;
}

class Complete extends Base {
  const Complete(super.id, this.label);

  final String label;

  @override
  bool operator ==(Object other) =>
      other is Complete && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

class Plain {
  const Plain(this.value);

  final int value;
}

class PlainChild extends Plain {
  const PlainChild(super.value);
}
