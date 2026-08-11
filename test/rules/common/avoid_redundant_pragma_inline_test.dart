import 'package:alig_lints/src/rules/common/avoid_redundant_pragma_inline.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidRedundantPragmaInline(CustomLintConfigs.empty);

  test('reports declarations with no inlinable body', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_redundant_pragma_inline.dart',
      onLines: [2, 9, 11, 18],
    );
  });

  test('fix removes the annotation line, leaving effective ones', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_redundant_pragma_inline.dart',
      expectedPath:
          'test/fixtures/common/avoid_redundant_pragma_inline.expected.dart',
    );
  });
}
