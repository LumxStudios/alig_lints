import 'package:alig_lints/src/rules/common/avoid_unused_parameters.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports unread parameters, skipping overrides and wildcards', () async {
    await expectRuleReports(
      AvoidUnusedParameters(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unused_parameters.dart',
      onLines: [1, 22],
    );
  });
}
