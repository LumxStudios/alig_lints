import 'package:alig_lints/src/rules/common/avoid_unused_instances.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports constructions used as a bare statement', () async {
    await expectRuleReports(
      AvoidUnusedInstances(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unused_instances.dart',
      onLines: [16, 17, 33],
    );
  });
}
