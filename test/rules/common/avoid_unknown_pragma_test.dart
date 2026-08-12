import 'package:alig_lints/src/rules/common/avoid_unknown_pragma.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports pragma values the toolchain does not know', () async {
    await expectRuleReports(
      AvoidUnknownPragma(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unknown_pragma.dart',
      onLines: [10, 13],
    );
  });
}
