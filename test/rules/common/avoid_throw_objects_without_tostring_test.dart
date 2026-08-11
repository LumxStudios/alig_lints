import 'package:alig_lints/src/rules/common/avoid_throw_objects_without_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports thrown types with no toString, not built-ins or abstracts',
      () async {
    await expectRuleReports(
      AvoidThrowObjectsWithoutTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_throw_objects_without_tostring.dart',
      onLines: [15],
    );
  });
}
