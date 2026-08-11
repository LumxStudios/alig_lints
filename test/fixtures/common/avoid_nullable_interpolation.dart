void log(String? name, int? count, String sure) {
  print('name: $name');
  print('count: $count');
  print('nested: ${name?.length}');

  print('sure: $sure');
  print('length: ${sure.length}');
  print('checked: ${name ?? 'unknown'}');
  print('asserted: ${name!}');
}
