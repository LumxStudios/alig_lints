import 'package:alig_lints/src/rules/common/avoid_unremovable_callbacks_in_listeners.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the leaking shape only', () async {
    await expectRuleReports(
      AvoidUnremovableCallbacksInListeners(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unremovable_callbacks_in_listeners.dart',
      onLines: [13],
    );
  });
}
