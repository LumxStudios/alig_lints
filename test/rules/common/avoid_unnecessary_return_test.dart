import 'package:alig_lints/src/rules/common/avoid_unnecessary_return.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryReturn(CustomLintConfigs.empty);

  test('reports trailing bare returns, not guard clauses', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_return.dart',
      onLines: [3, 7, 12],
    );
  });

  test('fix removes the whole line', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_return.dart',
      expectedPath: 'test/fixtures/common/avoid_unnecessary_return.expected.dart',
    );
  });
}
