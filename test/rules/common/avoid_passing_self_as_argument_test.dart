import 'package:alig_lints/src/rules/common/avoid_passing_self_as_argument.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports self arguments but not distinct objects or fresh calls',
      () async {
    await expectRuleReports(
      AvoidPassingSelfAsArgument(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_passing_self_as_argument.dart',
      onLines: [9, 20, 21, 22],
    );
  });
}
