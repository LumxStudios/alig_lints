import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-explicit-function-type',
  category: 'common',
  problemMessage: 'A bare Function says nothing about what this takes or '
      'returns, so every call to it is unchecked.',
  correctionMessage: 'Write the signature, for example `void Function(String)`.',
  tags: ['maintainability', 'correctness', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `Function` is used as a type without its signature.
///
/// ```dart
/// void register(Function callback) => callback();
/// ```
/// `Function` is to callables what `dynamic` is to values: any number of
/// arguments of any type compiles, and the ones that do not match fail at run
/// time. `void Function()` costs the same to write and makes `callback('x')` an
/// error where it belongs.
///
/// A bare `Function` in a type argument is reported too — `List<Function>` hides
/// exactly as much as a bare parameter does.
///
/// `thing is Function` and `thing as Function` are not reported. Asking whether
/// a value is callable at all is the one question the bare type answers well.
///
/// No quick-fix is offered: the signature has to come from what the callers
/// actually pass, and that is not written down anywhere the fix could read it.
class PreferExplicitFunctionType extends AligRule {
  /// Warns when a bare `Function` stands in for a signature.
  PreferExplicitFunctionType(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedType((node) {
      if (node.name.lexeme != 'Function') return;
      if (_isTypeTest(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [node] is the type of an `is` or `as`, where a bare `Function` is
/// asking whether the value is callable rather than describing a signature.
bool _isTypeTest(NamedType node) =>
    node.parent is IsExpression || node.parent is AsExpression;
