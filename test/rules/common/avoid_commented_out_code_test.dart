import 'package:alig_lints/src/rules/common/avoid_commented_out_code.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidCommentedOutCode(CustomLintConfigs.empty);

  test('reports runs of commented-out code, not prose or doc comments',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_commented_out_code.dart',
      onLines: [5, 21],
    );
  });

  test('fix removes the whole run of lines', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_commented_out_code.dart',
      expectedPath:
          'test/fixtures/common/avoid_commented_out_code.expected.dart',
    );
  });
}
