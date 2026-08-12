import 'package:alig_lints/src/rules/common/avoid_unassigned_stream_subscriptions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the leaking shape only', () async {
    await expectRuleReports(
      AvoidUnassignedStreamSubscriptions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unassigned_stream_subscriptions.dart',
      onLines: [7],
    );
  });
}
