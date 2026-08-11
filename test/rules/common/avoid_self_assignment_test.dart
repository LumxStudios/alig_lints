import 'package:alig_lints/src/rules/common/avoid_self_assignment.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidSelfAssignment(CustomLintConfigs.empty);

  test('reports self-assignments and nothing else', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_self_assignment.dart',
      onLines: [5, 11],
    );
  });

  test('fix removes the whole statement, leaving no blank line', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_self_assignment.dart',
      expectedPath: 'test/fixtures/common/avoid_self_assignment.expected.dart',
    );
  });
}
