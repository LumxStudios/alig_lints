import 'package:alig_lints/src/rules/common/avoid_unnecessary_reassignment.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryReassignment(CustomLintConfigs.empty);

  test('reports dead writes, stopping at reads and at control flow', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_reassignment.dart',
      onLines: [4, 11, 53],
    );
  });

  test('fix drops a declaration initializer, keeping the declaration', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_reassignment.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_reassignment.expected.dart',
    );
  });
}
