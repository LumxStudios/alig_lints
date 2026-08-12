import 'package:alig_lints/src/rules/common/avoid_renaming_representation_getters.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports getters that only return the representation field', () async {
    await expectRuleReports(
      AvoidRenamingRepresentationGetters(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_renaming_representation_getters.dart',
      onLines: [2, 10],
    );
  });
}
