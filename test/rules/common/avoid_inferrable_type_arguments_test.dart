import 'package:alig_lints/src/rules/common/avoid_inferrable_type_arguments.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidInferrableTypeArguments(CustomLintConfigs.empty);

  test('reports arguments the context already supplies, and nothing else',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_inferrable_type_arguments.dart',
      onLines: [9, 11, 13, 15, 18],
    );
  });

  test('fix deletes the type argument list', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_inferrable_type_arguments.dart',
      expectedPath:
          'test/fixtures/common/avoid_inferrable_type_arguments.expected.dart',
    );
  });
}
