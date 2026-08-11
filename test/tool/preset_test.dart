import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('dart_lints.yaml enables a non-empty set of built-in linter rules', () {
    final yaml =
        loadYaml(File('lib/dart_lints.yaml').readAsStringSync()) as Map;
    final rules = (yaml['linter'] as Map)['rules'] as List;

    expect(rules, contains('prefer_final_locals'));
    expect(rules, contains('always_declare_return_types'));
    expect(rules.length, greaterThan(50));
  });

  test('all.yaml wires up the custom_lint plugin and includes dart_lints', () {
    final content = File('lib/all.yaml').readAsStringSync();

    expect(content, contains('include: package:alig_lints/dart_lints.yaml'));
    expect(content, contains('- custom_lint'));
  });
}
