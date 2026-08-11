import 'package:alig_lints/src/rules/common/avoid_unnecessary_call.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryCall(CustomLintConfigs.empty);

  test('reports plain calls, not null-aware ones or cascades', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_call.dart',
      onLines: [12, 13],
    );
  });

  test('fix drops only the .call', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_call.dart',
      expectedPath: 'test/fixtures/common/avoid_unnecessary_call.expected.dart',
    );
  });
}
