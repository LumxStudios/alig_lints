import 'package:alig_lints/src/rules/common/no_equal_then_else.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = NoEqualThenElse(CustomLintConfigs.empty);

  test('reports equal branches in statements and conditionals', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/no_equal_then_else.dart',
      onLines: [4, 12, 18, 32],
    );
  });

  test('fix collapses only where the condition is side-effect-free', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/no_equal_then_else.dart',
      expectedPath: 'test/fixtures/common/no_equal_then_else.expected.dart',
    );
  });
}
