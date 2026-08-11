import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Typed access to the per-rule options block in `analysis_options.yaml`.
///
/// Given:
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid-unnecessary-setstate:
///         ignored-methods: ['refresh']
/// ```
/// `RuleOptions(configs, 'avoid-unnecessary-setstate').stringList('ignored-methods')`
/// returns `['refresh']`.
class RuleOptions {
  /// Reads the options block belonging to [ruleName].
  RuleOptions(CustomLintConfigs configs, String ruleName)
      : _json = configs.rules[ruleName]?.json ?? const {};

  final Map<String, Object?> _json;

  /// The string list at [key], or [orElse] when absent or malformed.
  List<String> stringList(String key, {List<String> orElse = const []}) {
    final value = _json[key];
    if (value is! List) return orElse;

    return value.whereType<String>().toList();
  }

  /// The boolean at [key], or [orElse] when absent or malformed.
  bool boolean(String key, {required bool orElse}) {
    final value = _json[key];

    return value is bool ? value : orElse;
  }

  /// The integer at [key], or [orElse] when absent or malformed.
  int integer(String key, {required int orElse}) {
    final value = _json[key];

    return value is int ? value : orElse;
  }
}
