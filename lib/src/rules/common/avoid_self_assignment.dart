import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-self-assignment',
  category: 'common',
  problemMessage:
      'This value is assigned to itself, so the assignment has no effect.',
  correctionMessage: 'Remove the assignment, or assign the intended value.',
  tags: ['correctness', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a variable or a class instance field is assigned to itself.
///
/// Catches plain `=` assignments where both sides resolve to the same
/// declaration, including `this.x = this.x` and `a.b.c = a.b.c`.
///
/// Deliberately not caught: compound assignments such as `a += a`, which do
/// have an effect; and any side where a getter or method is invoked, because
/// the invocation may have side effects.
class AvoidSelfAssignment extends AligRule {
  /// Warns when a value is assigned to itself.
  AvoidSelfAssignment(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((node) {
      if (node.operator.lexeme != '=') return;
      if (!_assignsToItself(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveSelfAssignment()];
}

/// Whether [node]'s target and value denote the same storage location.
bool _assignsToItself(AssignmentExpression node) {
  final target = _pathOf(node.leftHandSide, writeElement: node.writeElement);
  final value = _pathOf(node.rightHandSide);

  if (target == null || value == null) return false;
  if (target.length != value.length) return false;

  for (var i = 0; i < target.length; i++) {
    if (target[i] != value[i]) return false;
  }

  return true;
}

/// The chain of declarations [expression] walks through, outermost first, or
/// `null` when it is not a plain variable or field access chain.
///
/// Returning `null` for anything else is what keeps invocations — whose getters
/// may have side effects — out of scope.
///
/// [writeElement] overrides the element of the outermost segment. An assignment
/// target resolves to a setter, and on a property access the setter is recorded
/// on the assignment rather than on the property name, so the caller passes
/// `AssignmentExpression.writeElement` for the left-hand side.
List<Element>? _pathOf(Expression expression, {Element? writeElement}) {
  final node = expression.unParenthesized;

  if (node is ThisExpression) return const [];

  if (node is SimpleIdentifier) {
    final element = _underlyingVariable(writeElement ?? node.element);

    return element == null ? null : [element];
  }

  if (node is PrefixedIdentifier) {
    final prefix = _pathOf(node.prefix);
    final element =
        _underlyingVariable(writeElement ?? node.identifier.element);
    if (prefix == null || element == null) return null;

    return [...prefix, element];
  }

  if (node is PropertyAccess) {
    final targetExpression = node.target;
    if (targetExpression == null) return null;

    final target = _pathOf(targetExpression);
    final element =
        _underlyingVariable(writeElement ?? node.propertyName.element);
    if (target == null || element == null) return null;

    return [...target, element];
  }

  return null;
}

/// Reduces a getter or setter to the field or top-level variable it wraps, so
/// that a read and a write of the same property compare equal.
Element? _underlyingVariable(Element? element) => switch (element) {
      PropertyAccessorElement(:final variable) => variable,
      _ => element,
    };

class _RemoveSelfAssignment extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addAssignmentExpression((node) {
      if (!diagnostic.sourceRange.intersects(node.sourceRange)) return;

      final statement = node.parent;
      if (statement is! ExpressionStatement) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the self-assignment',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(lineRangeOf(statement, resolver));
      });
    });
  }
}
