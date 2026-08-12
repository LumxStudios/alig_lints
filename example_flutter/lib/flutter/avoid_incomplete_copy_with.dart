class Complete {
  const Complete({required this.name, required this.count, this.label});

  final String name;
  final int count;
  final String? label;

  Complete copyWith({String? name, int? count, String? label}) => Complete(
        name: name ?? this.name,
        count: count ?? this.count,
        label: label ?? this.label,
      );
}

class Incomplete {
  const Incomplete({required this.name, required this.count, this.label});

  final String name;
  final int count;
  final String? label;

  // expect_lint: avoid-incomplete-copy-with
  Incomplete copyWith({String? name}) => Incomplete(
        name: name ?? this.name,
        count: count,
        label: label,
      );
}

class NoCopyWith {
  const NoCopyWith({required this.name});

  final String name;
}

class Positional {
  const Positional(this.name);

  final String name;

  // A positional constructor has no parameter names to match up.
  Positional copyWith({String? name}) => Positional(name ?? this.name);
}
