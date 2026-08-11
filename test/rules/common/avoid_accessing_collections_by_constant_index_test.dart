import 'package:alig_lints/src/rules/common/avoid_accessing_collections_by_constant_index.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports constant indexes inside loops, not map lookups or reads outside',
      () async {
    await expectRuleReports(
      AvoidAccessingCollectionsByConstantIndex(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_accessing_collections_by_constant_index.dart',
      onLines: [3, 9],
    );
  });
}
