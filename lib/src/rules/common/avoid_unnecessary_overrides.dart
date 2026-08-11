import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-overrides',
  category: 'common',
  problemMessage: 'This override only forwards to the inherited member, so it '
      'changes nothing.',
  correctionMessage: 'Remove the override.',
  tags: ['correctness', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an override does nothing but forward to `super`.
///
/// Covers methods, getters, setters and operators whose entire body is the
/// corresponding `super` access, passing the parameters through unchanged.
///
/// Deliberately not reported when the declaration carries an annotation other
/// than `@override` — `@Deprecated`, `@protected`, `@visibleForTesting` and the
/// like. There the annotation is the point of the override, so the declaration is
/// not empty of meaning.
///
/// Dart ships an equivalent built-in lint, `unnecessary_overrides`. It is
/// switched off in `lib/dart_lints.yaml` so that a forwarding override collects
/// one warning rather than two; flip that line if you would rather use the
/// built-in.
class AvoidUnnecessaryOverrides extends AligRule {
  /// Warns when an override only forwards to super.
  AvoidUnnecessaryOverrides(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (!_onlyForwardsToSuper(node)) return;

      reporter.atToken(node.name, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveOverride()];
}

bool _onlyForwardsToSuper(MethodDeclaration node) {
  if (node.isAbstract) return false;
  if (_hasAnnotationBesidesOverride(node)) return false;

  final expression = _soleExpressionOf(node.body);
  if (expression == null) return false;

  if (node.isSetter) return _isMatchingSuperAssignment(node, expression);

  if (node.isGetter) {
    return expression is PropertyAccess &&
        expression.target is SuperExpression &&
        expression.propertyName.name == node.name.lexeme;
  }

  return _isMatchingSuperInvocation(node, expression);
}

/// Whether [node] carries metadata other than `@override`.
bool _hasAnnotationBesidesOverride(MethodDeclaration node) =>
    node.metadata.any((annotation) => annotation.name.name != 'override');

/// The single expression [body] evaluates, or `null` when the body does more.
Expression? _soleExpressionOf(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;

  if (body is BlockFunctionBody) {
    final statements = body.block.statements;
    if (statements.length != 1) return null;

    return switch (statements.single) {
      ExpressionStatement(:final expression) => expression,
      ReturnStatement(:final expression) => expression,
      _ => null,
    };
  }

  return null;
}

/// Whether [expression] is `super.name(...)` passing [node]'s parameters through
/// unchanged.
bool _isMatchingSuperInvocation(MethodDeclaration node, Expression expression) {
  if (expression is! MethodInvocation) return false;
  if (expression.target is! SuperExpression) return false;
  if (expression.methodName.name != node.name.lexeme) return false;

  final parameters = node.parameters?.parameters ?? const <FormalParameter>[];
  final arguments = expression.argumentList.arguments;
  if (arguments.length != parameters.length) return false;

  final positional = <String>[];
  final named = <String, String>{};
  for (final parameter in parameters) {
    final inner = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;
    final name = inner.name?.lexeme;
    if (name == null) return false;

    if (parameter.isNamed) {
      named[name] = name;
    } else {
      positional.add(name);
    }
  }

  var positionalIndex = 0;
  for (final argument in arguments) {
    if (argument is NamedExpression) {
      final label = argument.name.label.name;
      if (!named.containsKey(label)) return false;
      if (!_isReferenceTo(argument.expression, label)) return false;
      continue;
    }

    if (positionalIndex >= positional.length) return false;
    if (!_isReferenceTo(argument, positional[positionalIndex])) return false;
    positionalIndex++;
  }

  return positionalIndex == positional.length;
}

/// Whether [expression] is `super.name = value` where `value` is [node]'s only
/// parameter.
bool _isMatchingSuperAssignment(
  MethodDeclaration node,
  Expression expression,
) {
  if (expression is! AssignmentExpression) return false;
  if (expression.operator.lexeme != '=') return false;

  final target = expression.leftHandSide;
  if (target is! PropertyAccess) return false;
  if (target.target is! SuperExpression) return false;
  if (target.propertyName.name != node.name.lexeme) return false;

  final parameters = node.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 1) return false;

  final name = parameters.single.name?.lexeme;

  return name != null && _isReferenceTo(expression.rightHandSide, name);
}

bool _isReferenceTo(Expression expression, String name) {
  final node = expression.unParenthesized;

  return node is SimpleIdentifier && node.name == name;
}

class _RemoveOverride extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.offset != diagnostic.offset) return;
      if (!_onlyForwardsToSuper(node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the override',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // The declaration's own range starts after its metadata, so the
        // `@override` line has to be taken in explicitly.
        final start = node.metadata.beginToken?.offset ?? node.offset;
        fileBuilder.addDeletion(
          lineRangeOfSpan(start, node.end, resolver,
              absorbFollowingBlankLines: true),
        );
      });
    });
  }
}
