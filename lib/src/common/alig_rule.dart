import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Creates a rule instance for a given analysis configuration.
///
/// Rules are built per-config rather than being `const` so that options such as
/// `severity:` can be read out of `analysis_options.yaml`.
typedef AligRuleFactory = AligRule Function(CustomLintConfigs configs);

/// Static description of a rule, mirroring one entry of
/// `tool/rules_manifest.json`.
class AligRuleMeta {
  /// Static description of a rule.
  const AligRuleMeta({
    required this.name,
    required this.category,
    required this.problemMessage,
    this.correctionMessage,
    this.tags = const [],
    this.severity = DiagnosticSeverity.WARNING,
  });

  /// Kebab-case rule name, e.g. `avoid-self-assignment`.
  final String name;

  /// Either `common` or `flutter`.
  final String category;

  /// One-sentence explanation of what is wrong with the reported code.
  final String problemMessage;

  /// One-sentence explanation of how to fix the reported code.
  final String? correctionMessage;

  /// Classification tags carried over from DCM, e.g. `correctness`.
  final List<String> tags;

  /// Severity used unless overridden in `analysis_options.yaml`.
  final DiagnosticSeverity severity;

  /// Documentation page describing the equivalent DCM rule.
  String get url => 'https://dcm.dev/docs/rules/$category/$name/';

  /// Builds the [LintCode] for this rule, applying any `severity:` override.
  LintCode toCode(CustomLintConfigs configs) => LintCode(
        name: name,
        problemMessage: problemMessage,
        correctionMessage: correctionMessage,
        url: url,
        errorSeverity: _severityOverride(configs) ?? severity,
      );

  DiagnosticSeverity? _severityOverride(CustomLintConfigs configs) =>
      switch (configs.rules[name]?.json['severity']) {
        'error' => DiagnosticSeverity.ERROR,
        'warning' => DiagnosticSeverity.WARNING,
        'info' => DiagnosticSeverity.INFO,
        _ => null,
      };
}

/// Base class for every rule in this package.
abstract class AligRule extends DartLintRule {
  /// Base class for every rule in this package.
  AligRule(this.meta, this.configs) : super(code: meta.toCode(configs));

  /// Static description of this rule.
  final AligRuleMeta meta;

  /// The configuration this instance was built for.
  final CustomLintConfigs configs;
}
