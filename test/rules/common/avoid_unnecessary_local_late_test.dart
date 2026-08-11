import 'package:alig_lints/src/rules/common/avoid_unnecessary_local_late.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryLocalLate(CustomLintConfigs.empty);

  test('reports unconditional and both-branch assignments only', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_local_late.dart',
      onLines: [4, 11],
    );
  });

  test('fix removes late, leaving a final local assigned later', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_local_late.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_local_late.expected.dart',
    );
  });
}
