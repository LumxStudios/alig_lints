import 'package:alig_lints/src/rules/common/prefer_explicit_function_type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports bare Function types but not is or as tests', () async {
    await expectRuleReports(
      PreferExplicitFunctionType(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_explicit_function_type.dart',
      onLines: [1, 3, 6, 8],
    );
  });
}
