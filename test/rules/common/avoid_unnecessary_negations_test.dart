import 'package:alig_lints/src/rules/common/avoid_unnecessary_negations.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryNegations(CustomLintConfigs.empty);

  test('reports exact complements only, leaving relational negation alone',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_negations.dart',
      onLines: [7, 8, 9, 10, 11],
    );
  });

  test('fix folds the negation into the operator', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_negations.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_negations.expected.dart',
    );
  });
}
