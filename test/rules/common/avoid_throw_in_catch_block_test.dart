import 'package:alig_lints/src/rules/common/avoid_throw_in_catch_block.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidThrowInCatchBlock(CustomLintConfigs.empty);

  test('reports throwing the caught exception, not wrapping it', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_throw_in_catch_block.dart',
      onLines: [13, 21],
    );
  });

  test('fix replaces the throw with rethrow', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_throw_in_catch_block.dart',
      expectedPath:
          'test/fixtures/common/avoid_throw_in_catch_block.expected.dart',
    );
  });
}
