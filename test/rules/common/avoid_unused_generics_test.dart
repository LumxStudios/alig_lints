import 'package:alig_lints/src/rules/common/avoid_unused_generics.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports type parameters used nowhere in the declaration', () async {
    await expectRuleReports(
      AvoidUnusedGenerics(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unused_generics.dart',
      onLines: [1, 3, 20],
    );
  });
}
