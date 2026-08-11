import 'package:alig_lints/src/rules/common/avoid_unnecessary_conditionals.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryConditionals(CustomLintConfigs.empty);

  test('reports only boolean-literal branch pairs', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_conditionals.dart',
      onLines: [2, 3, 4, 5],
    );
  });

  test('fix parenthesises the condition only when negation needs it', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_conditionals.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_conditionals.expected.dart',
    );
  });
}
