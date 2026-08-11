void log(String? name, int? count, String sure) {
  // expect_lint: avoid-nullable-interpolation
  print('name: $name');
  // expect_lint: avoid-nullable-interpolation
  print('count: $count');
  // expect_lint: avoid-nullable-interpolation
  print('nested: ${name?.length}');

  print('sure: $sure');
  print('length: ${sure.length}');
  print('checked: ${name ?? 'unknown'}');
  print('asserted: ${name!}');
}
