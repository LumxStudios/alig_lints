import 'package:alig_lints/src/rules/common/prefer_public_exception_classes.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending declarations only', () async {
    await expectRuleReports(
      PreferPublicExceptionClasses(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_public_exception_classes.dart',
      onLines: [1, 10],
    );
  });
}
