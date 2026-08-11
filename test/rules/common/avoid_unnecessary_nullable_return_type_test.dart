import 'package:alig_lints/src/rules/common/avoid_unnecessary_nullable_return_type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryNullableReturnType(CustomLintConfigs.empty);

  test('reports only bodies that cannot hand back null', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_nullable_return_type.dart',
      onLines: [1, 3, 9, 30, 34, 38],
    );
  });

  test('fix drops the ? except on an overridable instance method', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_nullable_return_type.dart',
      expectedPath: 'test/fixtures/common/'
          'avoid_unnecessary_nullable_return_type.expected.dart',
    );
  });
}
