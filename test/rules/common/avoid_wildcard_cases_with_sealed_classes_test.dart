import 'package:alig_lints/src/rules/common/avoid_wildcard_cases_with_sealed_classes.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports catch-alls on sealed switches, not on open hierarchies',
      () async {
    await expectRuleReports(
      AvoidWildcardCasesWithSealedClasses(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_wildcard_cases_with_sealed_classes.dart',
      onLines: [11, 20, 27],
    );
  });
}
