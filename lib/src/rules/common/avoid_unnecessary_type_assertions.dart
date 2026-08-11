import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:analyzer/dart/element/type.dart';

import '../../common/alig_rule.dart';
import '../../common/null_checks.dart';
import '../../common/type_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-type-assertions',
  category: 'common',
  problemMessage: 'Every element already has this type, so this filters '
      'nothing out.',
  correctionMessage: 'Remove the call.',
  tags: ['correctness', 'unused-code', 'cwe', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a type filter on an iterable cannot remove anything.
///
/// ```dart
/// void show(Iterable<String> names) => print(names.whereType<String>());
/// ```
/// `whereType<String>` on an `Iterable<String>` keeps every element, so the call
/// costs a lazy wrapper and an extra line for nothing. It usually survives a
/// refactor: the elements were `Object` when it was written, and narrowing the
/// declaration left the filter behind.
///
/// `nonNulls` is reported the same way when the elements are already
/// non-nullable.
///
/// **The `is` half of this rule is left to the analyzer.** Dart's own
/// `unnecessary_type_check` — a warning that is on by default, not an opt-in
/// lint — already reports `text is String` and `text is! String` where the
/// static type settles the answer. What it does not report is a check between
/// unrelated types, and that gap is deliberately not filled here: proving two
/// types unrelated means proving no third type implements both, which holds for
/// `final` and `sealed` types and fails for ordinary classes. A rule that
/// guessed would report code that is merely defensive. The measurement behind
/// this is recorded in `doc/LIMITATIONS.md`.
///
/// No quick-fix is offered: removing the call is right when the filter is
/// genuinely stale, but the same report can mean the declared element type is
/// wrong instead, and deleting the filter would then hide that.
class AvoidUnnecessaryTypeAssertions extends AligRule {
  /// Warns when an iterable type filter keeps everything.
  AvoidUnnecessaryTypeAssertions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'whereType') return;

      final kept = node.typeArguments?.arguments.singleOrNull?.type;
      final element = iterableElementTypeOf(node.realTarget?.staticType);
      final typeSystem = typeSystemOf(node);
      if (kept == null || element == null || typeSystem == null) return;
      if (!typeSystem.isSubtypeOf(element, kept)) return;

      reporter.atNode(node.methodName, code);
    });

    // `values.nonNulls` parses as a property access only when the receiver is
    // itself an expression; on a plain name it is a prefixed identifier.
    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name != 'nonNulls') return;
      if (!_keepsEverything(node.realTarget.staticType)) return;

      reporter.atNode(node.propertyName, code);
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name != 'nonNulls') return;
      if (!_keepsEverything(node.prefix.staticType)) return;

      reporter.atNode(node.identifier, code);
    });

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'whereNotNull') return;
      if (node.argumentList.arguments.isNotEmpty) return;

      if (!_keepsEverything(node.realTarget?.staticType)) return;

      reporter.atNode(node.methodName, code);
    });
  }
}

/// Whether dropping nulls from an iterable of [type] would drop nothing.
bool _keepsEverything(DartType? type) {
  final element = iterableElementTypeOf(type);

  return element != null && !isNullableType(element);
}
