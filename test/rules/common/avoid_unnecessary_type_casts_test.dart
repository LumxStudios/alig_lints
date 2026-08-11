import 'package:alig_lints/src/rules/common/avoid_unnecessary_type_casts.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryTypeCasts(CustomLintConfigs.empty);

  test('reports casts that restate the existing arguments only', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_type_casts.dart',
      onLines: [6, 7],
    );
  });

  test('fix removes the call from the dot to the parenthesis', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_type_casts.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_type_casts.expected.dart',
    );
  });
}
