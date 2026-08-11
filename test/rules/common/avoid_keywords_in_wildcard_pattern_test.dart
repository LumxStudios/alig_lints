import 'package:alig_lints/src/rules/common/avoid_keywords_in_wildcard_pattern.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidKeywordsInWildcardPattern(CustomLintConfigs.empty);

  test('reports keywords on wildcards, not on named or plain patterns',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_keywords_in_wildcard_pattern.dart',
      onLines: [5, 12, 19],
    );
  });

  test('fix removes the keyword but keeps any type test', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_keywords_in_wildcard_pattern.dart',
      expectedPath: 'test/fixtures/common/'
          'avoid_keywords_in_wildcard_pattern.expected.dart',
    );
  });
}
