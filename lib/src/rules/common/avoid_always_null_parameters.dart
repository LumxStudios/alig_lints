import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/private_call_sites.dart';

const _meta = AligRuleMeta(
  name: 'avoid-always-null-parameters',
  category: 'common',
  problemMessage: 'Every call passes null for this parameter, so it carries no '
      'information.',
  correctionMessage: 'Remove the parameter and use null directly in the body, '
      'or pass a real value at some call site.',
  tags: ['correctness', 'maintainability', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private function or method has a parameter that is null at
/// every call.
///
/// ```dart
/// String _format(String text, String? prefix) => '${prefix ?? ''}$text';
///
/// void run() {
///   print(_format('a', null));
///   print(_format('b', null));
/// }
/// ```
/// `prefix` looks like a knob but no caller ever turns it, so the branch that
/// reads it is dead weight.
///
/// At least one caller has to pass `null` for this to be that caller's mistake.
/// An optional parameter nobody supplies at all is
/// `avoid-never-passed-parameters`' report — the two rules would otherwise both
/// fire on an optional with a null default, which is one defect and would read as
/// two.
///
/// Only private declarations are considered, and only those whose calls can all
/// be seen — `lib/src/common/private_call_sites.dart` says which those are and
/// what it cannot follow. `avoid-unnecessary-nullable-parameters` reads the same
/// call sites to reach the opposite conclusion.
///
/// A value that is null but not written `null` — a `const empty = null`, or a
/// variable the analyzer could prove null — does not count. Only the literal
/// does, so what the rule reports is what a reader can see at the call.
///
/// No quick-fix is offered. Deleting the parameter leaves every use of it in
/// the body undefined, so the repair is to rewrite that body around a known
/// null — a judgement about what the code should do, not a mechanical edit.
class AvoidAlwaysNullParameters extends AligRule {
  /// Warns when no caller ever passes a value for a private parameter.
  AvoidAlwaysNullParameters(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final callable in privateCallablesOf(unit)) {
        for (final parameter in callable.parameters.parameters) {
          if (_isAlwaysNull(parameter, callable.calls)) {
            reporter.atNode(parameter, code);
          }
        }
      }
    });
  }
}

/// Whether [parameter] receives null — explicitly or by default — at every one
/// of [calls].
bool _isAlwaysNull(FormalParameter parameter, List<ArgumentList> calls) {
  final element = parameter.declaredFragment?.element;
  if (element == null) return false;
  if (!_acceptsNull(element.type)) return false;

  // Omitting the argument only means "null" when the default says so.
  final defaultsToNull = defaultValueOf(parameter) == null;
  var passedExplicitly = false;

  for (final call in calls) {
    final argument = argumentFor(element, call);
    if (argument == null) {
      if (!defaultsToNull) return false;
      continue;
    }
    if (argument.unParenthesized is! NullLiteral) return false;
    passedExplicitly = true;
  }

  // A parameter no caller supplies at all is
  // `avoid-never-passed-parameters`' report, not this one: the two would
  // otherwise both fire on an optional with a null default.
  return passedExplicitly;
}

/// Whether a null argument would even be legal for [type].
bool _acceptsNull(DartType type) =>
    type is DynamicType || type.nullabilitySuffix == NullabilitySuffix.question;
