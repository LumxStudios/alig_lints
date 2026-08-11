import 'package:alig_lints/src/rules/common/avoid_unnecessary_continue.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryContinue(CustomLintConfigs.empty);

  test('reports trailing continues, not guards or labelled jumps', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_continue.dart',
      onLines: [4, 10],
    );
  });

  test('fix removes the whole line', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_continue.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_continue.expected.dart',
    );
  });
}
