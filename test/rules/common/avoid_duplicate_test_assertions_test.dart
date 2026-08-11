import 'package:alig_lints/src/rules/common/avoid_duplicate_test_assertions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicateTestAssertions(CustomLintConfigs.empty);

  test('reports repeats within one test, ignoring reason and side effects',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_test_assertions.dart',
      onLines: [12, 17],
    );
  });

  test('fix removes the repeated assertion statement', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_test_assertions.dart',
      expectedPath:
          'test/fixtures/common/avoid_duplicate_test_assertions.expected.dart',
    );
  });
}
