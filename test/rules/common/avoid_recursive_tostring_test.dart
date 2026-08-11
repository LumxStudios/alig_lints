import 'package:alig_lints/src/rules/common/avoid_recursive_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports self-calls and interpolated this, not super', () async {
    await expectRuleReports(
      AvoidRecursiveTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_recursive_tostring.dart',
      onLines: [8, 14],
    );
  });
}
