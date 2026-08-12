import 'package:alig_lints/src/rules/common/avoid_uncaught_future_errors.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports stored futures no await in the try reaches', () async {
    await expectRuleReports(
      AvoidUncaughtFutureErrors(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_uncaught_future_errors.dart',
      onLines: [5],
    );
  });
}
