import 'dart:convert';

void decode(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;

  // expect_lint: prefer-correct-json-casts
  print(jsonDecode(source) as Map<String, String>);
  // expect_lint: prefer-correct-json-casts
  print(root['items'] as List<String>);
  // expect_lint: prefer-correct-json-casts
  print(root['rows'] as List<Map<String, dynamic>>);

  // The decoder really does produce these.
  print(root['items'] as List<dynamic>);
  print(root['nested'] as Map<String, dynamic>);
  print(root['name'] as String);
  print(root['count'] as int);

  // Converting after a correct cast is the way to get the narrow type.
  final rows = (root['rows'] as List<dynamic>).cast<Map<String, dynamic>>();
  print(rows);
}
