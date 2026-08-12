import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'flutter_utils.dart';

/// Reports a freshly created source handed to an async builder widget.
///
/// Shared by `pass-existing-future-to-future-builder` and its stream sibling:
/// both ask the same question of the same argument shape, so what counts as
/// "freshly created" lives here rather than in each of them.
void reportFreshBuilderSource(
  CustomLintContext context,
  DiagnosticReporter reporter,
  LintCode code, {
  required String widget,
  required String argument,
  required String libraryPath,
}) {
  context.registry.addInstanceCreationExpression((node) {
    final type = node.staticType;
    if (type is! InterfaceType) return;
    if (!hasFlutterSupertype(type.element, widget, libraryPath)) return;

    final source = _namedArgument(node, argument);
    if (source == null || !isFreshlyCreated(source)) return;

    reporter.atNode(source, code);
  });
}

/// Whether [expression] builds something new every time it is evaluated.
///
/// A name — a field, a local, `widget.something` — refers to a value created
/// somewhere else and is left alone. A call or a literal produces a new object on
/// each rebuild, which is the defect.
bool isFreshlyCreated(Expression expression) {
  final node = expression.unParenthesized;

  return switch (node) {
    SimpleIdentifier() => false,
    PrefixedIdentifier() => false,
    PropertyAccess() => false,
    ThisExpression() => false,
    // `condition ? a : b` is only fresh if a branch is.
    ConditionalExpression(:final thenExpression, :final elseExpression) =>
      isFreshlyCreated(thenExpression) || isFreshlyCreated(elseExpression),
    BinaryExpression(operator: Token(lexeme: '??'), :final leftOperand) =>
      isFreshlyCreated(leftOperand),
    _ => true,
  };
}

/// The expression passed as [name], or null when the call does not pass it.
Expression? _namedArgument(InstanceCreationExpression node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      return argument.expression;
    }
  }

  return null;
}
