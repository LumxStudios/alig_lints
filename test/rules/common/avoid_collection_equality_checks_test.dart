import 'package:alig_lints/src/rules/common/avoid_collection_equality_checks.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports identity-compared collections, not value-equal types', () async {
    await expectRuleReports(
      AvoidCollectionEqualityChecks(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_collection_equality_checks.dart',
      onLines: [15, 16, 20],
    );
  });
}
