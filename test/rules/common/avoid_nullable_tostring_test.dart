import 'package:alig_lints/src/rules/common/avoid_nullable_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports unconditional calls on nullable receivers only', () async {
    await expectRuleReports(
      AvoidNullableTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_nullable_tostring.dart',
      onLines: [2, 3, 4],
    );
  });
}
