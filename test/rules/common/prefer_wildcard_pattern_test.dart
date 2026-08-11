import 'package:alig_lints/src/rules/common/prefer_wildcard_pattern.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferWildcardPattern(CustomLintConfigs.empty);

  test('reports types that exclude nothing, keeping Object on a nullable value',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_wildcard_pattern.dart',
      onLines: [5, 14, 23],
    );
  });

  test('fix removes the type and the space after it', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_wildcard_pattern.dart',
      expectedPath: 'test/fixtures/common/prefer_wildcard_pattern.expected.dart',
    );
  });
}
