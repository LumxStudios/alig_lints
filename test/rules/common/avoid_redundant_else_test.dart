import 'package:alig_lints/src/rules/common/avoid_redundant_else.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidRedundantElse(CustomLintConfigs.empty);

  test('reports only elses whose then branch always exits', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_redundant_else.dart',
      onLines: [4, 12],
    );
  });

  test('fix unwraps a multi-line body and re-indents it one level left',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_redundant_else.dart',
      expectedPath: 'test/fixtures/common/avoid_redundant_else.expected.dart',
    );
  });
}
