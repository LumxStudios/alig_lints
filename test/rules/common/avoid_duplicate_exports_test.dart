import 'package:alig_lints/src/rules/common/avoid_duplicate_exports.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicateExports(CustomLintConfigs.empty);

  test('reports every repeat of a URI, combinators or not', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_exports.dart',
      onLines: [2, 5],
    );
  });

  test('fix deletes only the redundant declaration, not the narrowed one',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_exports.dart',
      expectedPath: 'test/fixtures/common/avoid_duplicate_exports.expected.dart',
    );
  });
}
