import 'package:alig_lints/src/rules/common/avoid_future_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports futures stringified explicitly and by interpolation', () async {
    await expectRuleReports(
      AvoidFutureTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_future_tostring.dart',
      onLines: [8, 9, 10, 11],
    );
  });
}
