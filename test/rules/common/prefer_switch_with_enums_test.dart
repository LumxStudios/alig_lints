import 'package:alig_lints/src/rules/common/prefer_switch_with_enums.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports chains dispatching on one enum, not mixed or multi-subject ones',
      () async {
    await expectRuleReports(
      PreferSwitchWithEnums(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_switch_with_enums.dart',
      onLines: [4],
    );
  });

  test('threshold raises how many comparisons are needed', () async {
    const configs = CustomLintConfigs(
      enableAllLintRules: null,
      verbose: false,
      debug: false,
      rules: {
        'prefer-switch-with-enums': LintOptions.fromYaml(
          {'threshold': 3},
          enabled: true,
        ),
      },
    );

    await expectRuleReports(
      PreferSwitchWithEnums(configs),
      'test/fixtures/common/prefer_switch_with_enums.dart',
      onLines: [],
    );
  });
}
