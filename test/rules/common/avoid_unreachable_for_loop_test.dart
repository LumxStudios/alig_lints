import 'package:alig_lints/src/rules/common/avoid_unreachable_for_loop.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports loops the enclosing condition rules out, in either branch',
      () async {
    await expectRuleReports(
      AvoidUnreachableForLoop(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unreachable_for_loop.dart',
      onLines: [3, 11, 21],
    );
  });
}
