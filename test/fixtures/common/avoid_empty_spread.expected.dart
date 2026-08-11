void main() {
  final numbers = [1, 2];

  final combined = <int>[
    ...numbers,
  ];

  final unique = <int>{
    ...numbers,
  };

  final inline = <int>[...numbers, 3];

  final fine = <int>[...numbers, ...[3, 4]];

  print([combined, unique, inline, fine]);
}
