import 'package:alig_lints/src/rules/common/avoid_unnecessary_futures.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports async bodies with no await, skipping overrides', () async {
    await expectRuleReports(
      AvoidUnnecessaryFutures(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unnecessary_futures.dart',
      onLines: [1, 3],
    );
  });
}
