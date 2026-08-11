import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/null_checks.dart';
import '../../common/private_call_sites.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-nullable-parameters',
  category: 'common',
  problemMessage: 'No call passes null for this parameter, so the ? promises a '
      'case that never arrives.',
  correctionMessage: 'Make the type non-nullable.',
  tags: ['correctness', 'maintainability', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private parameter is nullable but never gets a null.
///
/// ```dart
/// String? _pick(String text, String? fallback) =>
///     text.isEmpty ? fallback : text;
///
/// void run() {
///   print(_pick('a', 'b'));
///   print(_pick('', 'c'));
/// }
/// ```
/// The `?` says callers may leave this out, and none of them does. It costs
/// every reader of the body a moment deciding what the null case means, and the
/// answer is that there is no null case.
///
/// Only private declarations are considered, and only those whose calls can all
/// be seen — `lib/src/common/private_call_sites.dart` says which those are and
/// what it cannot follow. `avoid-always-null-parameters` reads the same call
/// sites to reach the opposite conclusion.
///
/// An optional parameter counts as getting a null when it is left out and its
/// default is null; when the default is a real value, omitting it supplies that
/// value and the parameter is still reported.
///
/// The fix removes the `?`, but only where the body does not already handle the
/// null. A body containing `width ?? 0`, `width!`, `width?.foo` or a comparison
/// against null is reported without a fix: dropping the `?` there would leave a
/// branch that can never be taken, and deciding what should replace it is the
/// author's call, not a keystroke's.
class AvoidUnnecessaryNullableParameters extends AligRule {
  /// Warns when a private nullable parameter never receives null.
  AvoidUnnecessaryNullableParameters(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final callable in privateCallablesOf(unit)) {
        for (final parameter in callable.parameters.parameters) {
          if (_isNeverNull(parameter, callable.calls)) {
            reporter.atNode(parameter, code);
          }
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_MakeNonNullable()];
}

/// Whether [parameter] is declared nullable yet receives a non-null value at
/// every one of [calls].
bool _isNeverNull(FormalParameter parameter, List<ArgumentList> calls) {
  final element = parameter.declaredFragment?.element;
  if (element == null) return false;
  if (element.type.nullabilitySuffix != NullabilitySuffix.question) {
    return false;
  }

  final defaultValue = defaultValueOf(parameter);
  // Leaving out a parameter with no default supplies null.
  final defaultsToNull = defaultValue == null || defaultValue is NullLiteral;

  for (final call in calls) {
    final argument = argumentFor(element, call);
    if (argument == null) {
      if (defaultsToNull) return false;
      continue;
    }

    final type = argument.staticType;
    if (type == null || isNullableType(type)) return false;
  }

  return true;
}

/// The `?` on [parameter]'s written type, or null when there is no plain type
/// annotation to edit.
Token? _questionTokenOf(FormalParameter parameter) {
  final inner =
      parameter is DefaultFormalParameter ? parameter.parameter : parameter;
  if (inner is! SimpleFormalParameter) return null;

  return switch (inner.type) {
    NamedType(:final question) => question,
    GenericFunctionType(:final question) => question,
    _ => null,
  };
}

class _MakeNonNullable extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addFormalParameterList((list) {
      for (final parameter in list.parameters) {
        if (parameter.sourceRange != diagnostic.sourceRange) continue;

        final question = _questionTokenOf(parameter);
        final element = parameter.declaredFragment?.element;
        if (question == null || element == null) return;
        // Dropping the ? here would leave a branch that can never be taken.
        if (_bodyHandlesNull(parameter, element)) return;

        reporter
            .createChangeBuilder(
              message: 'Make the parameter non-nullable',
              priority: 60,
            )
            .addDartFileEdit((builder) {
          builder.addDeletion(SourceRange(question.offset, question.length));
        });
      }
    });
  }
}

/// Whether the body [parameter] belongs to already treats it as possibly null.
///
/// The body is a sibling of the parameter list rather than an ancestor of the
/// parameter, so it is reached through the declaration that owns both.
bool _bodyHandlesNull(
  FormalParameter parameter,
  FormalParameterElement element,
) {
  final list = parameter.thisOrAncestorOfType<FormalParameterList>();
  final body = switch (list?.parent) {
    FunctionExpression(:final body) => body,
    MethodDeclaration(:final body) => body,
    ConstructorDeclaration(:final body) => body,
    _ => null,
  };
  // Without a body in view there is no way to tell, so leave the code alone.
  if (body == null) return true;

  final visitor = _NullHandlingDetector(element);
  body.accept(visitor);

  return visitor.found;
}

/// Looks for uses of one parameter that only make sense if it can be null.
class _NullHandlingDetector extends RecursiveAstVisitor<void> {
  _NullHandlingDetector(this._element);

  final FormalParameterElement _element;
  bool found = false;

  bool _isParameter(Expression? expression) =>
      expression is SimpleIdentifier && expression.element == _element;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    if (operator == TokenType.QUESTION_QUESTION && _isParameter(node.leftOperand)) {
      found = true;
    }
    final isNullTest = operator == TokenType.EQ_EQ || operator == TokenType.BANG_EQ;
    if (isNullTest &&
        (_isParameter(node.leftOperand) && node.rightOperand is NullLiteral ||
            _isParameter(node.rightOperand) && node.leftOperand is NullLiteral)) {
      found = true;
    }

    super.visitBinaryExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // Reassigning the parameter can put a null back into it.
    if (_isParameter(node.leftHandSide)) found = true;

    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type == TokenType.BANG && _isParameter(node.operand)) {
      found = true;
    }

    super.visitPostfixExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.isNullAware && _isParameter(node.target)) found = true;

    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.isNullAware && _isParameter(node.target)) found = true;

    super.visitMethodInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (node.isNullAware && _isParameter(node.target)) found = true;

    super.visitIndexExpression(node);
  }
}
