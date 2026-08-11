import 'package:alig_lints/src/rules/common/prefer_correct_for_loop_increment.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports updates disjoint from the condition, not external conditions',
      () async {
    await expectRuleReports(
      PreferCorrectForLoopIncrement(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_correct_for_loop_increment.dart',
      onLines: [6, 15],
    );
  });
}
