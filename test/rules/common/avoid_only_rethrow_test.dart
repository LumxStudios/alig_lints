import 'package:alig_lints/src/rules/common/avoid_only_rethrow.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports only a trailing rethrow-only clause', () async {
    await expectRuleReports(
      AvoidOnlyRethrow(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_only_rethrow.dart',
      onLines: [6, 33],
    );
  });
}
