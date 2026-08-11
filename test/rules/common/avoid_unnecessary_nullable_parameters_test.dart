import 'package:alig_lints/src/rules/common/avoid_unnecessary_nullable_parameters.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryNullableParameters(CustomLintConfigs.empty);

  test('reports nullable parameters no call leaves null', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_nullable_parameters.dart',
      onLines: [2, 12, 21],
    );
  });

  test('fix drops the ? only where the body does not handle null', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_nullable_parameters.dart',
      expectedPath: 'test/fixtures/common/'
          'avoid_unnecessary_nullable_parameters.expected.dart',
    );
  });
}
