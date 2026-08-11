import 'package:alig_lints/src/rules/common/avoid_duplicate_constant_values.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the repeated constant in a class and in an enum', () async {
    await expectRuleReports(
      AvoidDuplicateConstantValues(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_duplicate_constant_values.dart',
      onLines: [4, 10],
    );
  });

  test('ignored-values suppresses the configured literals', () async {
    const configs = CustomLintConfigs(
      enableAllLintRules: null,
      verbose: false,
      debug: false,
      rules: {
        'avoid-duplicate-constant-values': LintOptions.fromYaml(
          {
            'ignored-values': ['5'],
          },
          enabled: true,
        ),
      },
    );

    await expectRuleReports(
      AvoidDuplicateConstantValues(configs),
      'test/fixtures/common/avoid_duplicate_constant_values.dart',
      onLines: [10],
    );
  });
}
