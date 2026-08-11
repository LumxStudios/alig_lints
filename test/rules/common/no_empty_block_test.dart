import 'package:alig_lints/src/rules/common/no_empty_block.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports empty statement blocks, not catches or function bodies',
      () async {
    await expectRuleReports(
      NoEmptyBlock(CustomLintConfigs.empty),
      'test/fixtures/common/no_empty_block.dart',
      onLines: [4, 8, 10, 12, 14, 18, 20],
    );
  });
}
