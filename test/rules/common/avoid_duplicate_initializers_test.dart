import 'package:alig_lints/src/rules/common/avoid_duplicate_initializers.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports only the repeated side-effect-free non-literal initializer',
      () async {
    await expectRuleReports(
      AvoidDuplicateInitializers(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_duplicate_initializers.dart',
      onLines: [12],
    );
  });
}
