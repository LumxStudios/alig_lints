import 'package:alig_lints/src/rules/common/avoid_unnecessary_extends.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryExtends(CustomLintConfigs.empty);

  test('reports Object supertypes and Object? bounds, not real constraints',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_extends.dart',
      onLines: [1, 7, 13, 15, 17],
    );
  });

  test('fix removes the clause and the extends keyword with it', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_extends.dart',
      expectedPath: 'test/fixtures/common/avoid_unnecessary_extends.expected.dart',
    );
  });
}
