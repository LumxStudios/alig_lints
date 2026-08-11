import 'package:alig_lints/src/rules/common/avoid_unsafe_collection_methods.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnsafeCollectionMethods(CustomLintConfigs.empty);

  test('reports throwing accesses, not orElse forms or non-empty literals',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unsafe_collection_methods.dart',
      onLines: [2, 3, 4, 8, 9, 10],
    );
  });

  test('names the member in the message', () async {
    final diagnostics = await runRule(
      rule,
      'test/fixtures/common/avoid_unsafe_collection_methods.dart',
    );

    expect(diagnostics.first.message, contains('first'));
  });
}
