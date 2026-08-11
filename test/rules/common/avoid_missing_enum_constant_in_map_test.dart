import 'package:alig_lints/src/rules/common/avoid_missing_enum_constant_in_map.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidMissingEnumConstantInMap(CustomLintConfigs.empty);

  test('reports partial enum maps, not complete or opaque ones', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_missing_enum_constant_in_map.dart',
      onLines: [3],
    );
  });

  test('names the missing constants in the message', () async {
    final diagnostics = await runRule(
      rule,
      'test/fixtures/common/avoid_missing_enum_constant_in_map.dart',
    );

    expect(diagnostics.single.message, contains('stopped'));
  });
}
