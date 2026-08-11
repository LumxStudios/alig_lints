import 'package:alig_lints/src/rules/common/avoid_nullable_interpolation.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports nullable values, not ones the type system has ruled out',
      () async {
    await expectRuleReports(
      AvoidNullableInterpolation(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_nullable_interpolation.dart',
      onLines: [2, 3, 4],
    );
  });
}
