import 'package:alig_lints/src/rules/common/avoid_unnecessary_overrides.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryOverrides(CustomLintConfigs.empty);

  test('reports pure forwarders across methods, getters and setters', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_overrides.dart',
      onLines: [13, 18, 21, 24],
    );
  });

  test('fix removes the declaration together with its @override', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_overrides.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_overrides.expected.dart',
    );
  });
}
