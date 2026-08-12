import 'package:alig_lints/src/rules/common/prefer_declaring_const_constructor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferDeclaringConstConstructor(CustomLintConfigs.empty);

  test('reports only the shape where const is guaranteed to compile', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_declaring_const_constructor.dart',
      onLines: [2],
    );
  });

  test('fix inserts const', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_declaring_const_constructor.dart',
      expectedPath: 'test/fixtures/common/'
          'prefer_declaring_const_constructor.expected.dart',
    );
  });
}
