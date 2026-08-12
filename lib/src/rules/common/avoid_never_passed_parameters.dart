import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/private_call_sites.dart';

const _meta = AligRuleMeta(
  name: 'avoid-never-passed-parameters',
  category: 'common',
  problemMessage: 'No call supplies this optional parameter, so it always takes '
      'its default and the choice it offers is not one anybody makes.',
  correctionMessage: 'Remove the parameter and use the default value directly.',
  tags: ['unused-code', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private declaration's optional parameter is never supplied.
///
/// ```dart
/// String _label(String text, {String suffix = '!'}) => '$text$suffix';
///
/// void run() {
///   print(_label('a'));
///   print(_label('b'));
/// }
/// ```
/// The parameter reads as a decision the callers make, and none of them makes it.
/// Every reader of `_label` has to work out what varies here, and the answer is
/// nothing — the default is the only value the function has ever seen.
///
/// This is the third rule reading the same call sites, and they partition:
///
/// - **this one** — the parameter is never supplied at all;
/// - `avoid-always-null-parameters` — some caller passes an explicit `null` and they
///   all do;
/// - `avoid-unnecessary-nullable-parameters` — the callers all pass a value, so the
///   `?` is unnecessary.
///
/// The first two would otherwise both fire on an optional with a null default, so
/// `avoid-always-null-parameters` requires a caller that actually writes `null`.
///
/// Only private declarations whose calls can all be seen are considered;
/// `lib/src/common/private_call_sites.dart` says which those are and what it cannot
/// follow.
///
/// No quick-fix is offered. Removing the parameter means substituting the default
/// wherever the body used it, and where the default is a constructor call or depends
/// on other arguments, that substitution is not a copy.
class AvoidNeverPassedParameters extends AligRule {
  /// Warns when an optional parameter no caller supplies.
  AvoidNeverPassedParameters(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final callable in privateCallablesOf(unit)) {
        for (final parameter in callable.parameters.parameters) {
          if (!parameter.isOptional) continue;
          if (_isSuppliedByAnyCall(parameter, callable.calls)) continue;

          reporter.atNode(parameter, code);
        }
      }
    });
  }
}

/// Whether any of [calls] passes [parameter] at all.
bool _isSuppliedByAnyCall(
  FormalParameter parameter,
  List<ArgumentList> calls,
) {
  final element = parameter.declaredFragment?.element;
  // Without an element there is nothing to match arguments against, so say yes
  // and stay quiet.
  if (element == null) return true;

  for (final call in calls) {
    if (argumentFor(element, call) != null) return true;
  }

  return false;
}
