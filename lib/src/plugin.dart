import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'registry.dart';

/// The custom_lint plugin exposing every alig_lints rule.
class AligLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) =>
      [for (final factory in aligRuleFactories) factory(configs)];
}
