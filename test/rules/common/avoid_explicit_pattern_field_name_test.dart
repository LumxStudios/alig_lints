import 'package:alig_lints/src/rules/common/avoid_explicit_pattern_field_name.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidExplicitPatternFieldName(CustomLintConfigs.empty);

  test('reports names the shorthand covers, not renaming patterns', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_explicit_pattern_field_name.dart',
      onLines: [10, 10],
    );
  });

  test('fix drops the name and keeps the colon', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_explicit_pattern_field_name.dart',
      expectedPath:
          'test/fixtures/common/avoid_explicit_pattern_field_name.expected.dart',
    );
  });
}
