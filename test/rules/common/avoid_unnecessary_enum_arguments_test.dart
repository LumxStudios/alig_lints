import 'package:alig_lints/src/rules/common/avoid_unnecessary_enum_arguments.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryEnumArguments(CustomLintConfigs.empty);

  test('reports empty argument lists, not named constructors', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_enum_arguments.dart',
      onLines: [2, 3],
    );
  });

  test('fix removes the parentheses', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_enum_arguments.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_enum_arguments.expected.dart',
    );
  });
}
