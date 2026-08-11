import 'package:alig_lints/src/rules/common/avoid_unnecessary_late_fields.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryLateFields(CustomLintConfigs.empty);

  test('reports only fields every constructor initializes up front', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_late_fields.dart',
      onLines: [4, 10],
    );
  });

  test('fix removes late without disturbing the indentation', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_late_fields.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_late_fields.expected.dart',
    );
  });
}
