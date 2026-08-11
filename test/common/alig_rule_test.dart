import 'package:alig_lints/src/common/alig_rule.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

const _meta = AligRuleMeta(
  name: 'avoid-self-assignment',
  category: 'common',
  problemMessage: 'This assignment has no effect.',
  correctionMessage: 'Remove the assignment or assign a different value.',
  tags: ['correctness', 'assignments'],
);

void main() {
  test('builds a LintCode with the rule name and default severity', () {
    final code = _meta.toCode(CustomLintConfigs.empty);

    expect(code.name, 'avoid-self-assignment');
    expect(code.errorSeverity, DiagnosticSeverity.WARNING);
  });

  test('severity can be overridden per rule from analysis_options', () {
    const configs = CustomLintConfigs(
      enableAllLintRules: null,
      verbose: false,
      debug: false,
      rules: {
        'avoid-self-assignment': LintOptions.fromYaml(
          {'severity': 'info'},
          enabled: true,
        ),
      },
    );

    expect(_meta.toCode(configs).errorSeverity, DiagnosticSeverity.INFO);
  });
}
