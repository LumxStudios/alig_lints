import 'package:alig_lints/src/rules/common/avoid_dynamic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports declaration types, not dynamic inside a type argument',
      () async {
    await expectRuleReports(
      AvoidDynamic(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_dynamic.dart',
      onLines: [1, 4, 6, 8, 20, 27],
    );
  });
}
