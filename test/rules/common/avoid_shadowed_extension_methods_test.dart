import 'package:alig_lints/src/rules/common/avoid_shadowed_extension_methods.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports members the extended type already declares', () async {
    await expectRuleReports(
      AvoidShadowedExtensionMethods(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_shadowed_extension_methods.dart',
      onLines: [8, 10, 16],
    );
  });
}
