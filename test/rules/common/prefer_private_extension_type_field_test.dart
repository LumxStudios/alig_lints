import 'package:alig_lints/src/rules/common/prefer_private_extension_type_field.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending declarations only', () async {
    await expectRuleReports(
      PreferPrivateExtensionTypeField(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_private_extension_type_field.dart',
      onLines: [1],
    );
  });
}
