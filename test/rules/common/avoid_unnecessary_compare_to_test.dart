import 'package:alig_lints/src/rules/common/avoid_unnecessary_compare_to.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryCompareTo(CustomLintConfigs.empty);

  test('reports equality checks on safe types only', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_compare_to.dart',
      onLines: [9, 10, 11],
    );
  });

  test('fix rewrites to the operator, whichever side the zero is on', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_compare_to.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_compare_to.expected.dart',
    );
  });
}
