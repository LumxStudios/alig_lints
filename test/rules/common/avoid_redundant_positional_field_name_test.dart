import 'package:alig_lints/src/rules/common/avoid_redundant_positional_field_name.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidRedundantPositionalFieldName(CustomLintConfigs.empty);

  test('reports positional field names, not named fields', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_redundant_positional_field_name.dart',
      onLines: [1, 3, 3],
    );
  });

  test('fix removes the name and the space before it', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_redundant_positional_field_name.dart',
      expectedPath: 'test/fixtures/common/'
          'avoid_redundant_positional_field_name.expected.dart',
    );
  });
}
