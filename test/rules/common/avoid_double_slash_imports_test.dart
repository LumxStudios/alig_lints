import 'package:alig_lints/src/rules/common/avoid_double_slash_imports.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDoubleSlashImports(CustomLintConfigs.empty);

  test('reports doubled slashes in directive URIs', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_double_slash_imports.dart',
      onLines: [1, 2],
    );
  });

  test('fix collapses the doubled slash', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_double_slash_imports.dart',
      expectedPath:
          'test/fixtures/common/avoid_double_slash_imports.expected.dart',
    );
  });
}
