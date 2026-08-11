import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-returning-shorthands',
  category: 'common',
  problemMessage: 'The return type already names this type, so the shorthand '
      'says the same thing.',
  correctionMessage: 'Drop the type name and keep the dot.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests the dot shorthand when an expression body returns a member of its own
/// return type.
///
/// `Color favourite() => Color.red;` repeats `Color` on the same line; `=> .red`
/// resolves against the declared return type and reads the same.
///
/// Covers static members, static methods and named constructors.
///
/// Unnamed constructors are left alone. `Box make() => Box();` would become
/// `=> .new();`, which names the constructor in a more roundabout way than
/// writing the type did — the opposite of what this rule is for.
///
/// The named type has to match the return type exactly. A subtype would resolve
/// differently under the shorthand, which looks up the *return* type's namespace.
class PreferReturningShorthands extends AligRule {
  /// Suggests a dot shorthand in an expression body.
  PreferReturningShorthands(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _check(reporter, node.returnType, node.functionExpression.body);
    });

    context.registry.addMethodDeclaration(
      (node) => _check(reporter, node.returnType, node.body),
    );
  }

  void _check(
    DiagnosticReporter reporter,
    TypeAnnotation? returnType,
    FunctionBody body,
  ) {
    if (returnType is! NamedType) return;
    if (body is! ExpressionFunctionBody) return;
    if (body.keyword != null) return;

    final range = _typePrefixRangeOf(body.expression, returnType);
    if (range == null) return;

    reporter.atOffset(offset: range.offset, length: range.length, diagnosticCode: code);
  }

  @override
  List<Fix> getFixes() => [_UseShorthand()];
}

/// The range covering the redundant type name in [expression], or `null` when the
/// expression does not name [returnType].
SourceRange? _typePrefixRangeOf(Expression expression, NamedType returnType) {
  final wanted = returnType.element;
  if (wanted == null) return null;

  final node = expression.unParenthesized;

  // `Color.red` and `Size.small`.
  if (node is PrefixedIdentifier) {
    return _matches(node.prefix.element, wanted)
        ? SourceRange(node.prefix.offset, node.prefix.length)
        : null;
  }

  // `Size.of(value)`.
  if (node is MethodInvocation) {
    final target = node.target;
    if (target is SimpleIdentifier && _matches(target.element, wanted)) {
      return SourceRange(target.offset, target.length);
    }

    return null;
  }

  // `Size.large()`. An unnamed constructor would only become `.new(...)`, which
  // is not an improvement, so it is not reported.
  if (node is InstanceCreationExpression) {
    if (node.constructorName.name == null) return null;

    final type = node.constructorName.type;

    return _matches(type.element, wanted)
        ? SourceRange(type.offset, type.length)
        : null;
  }

  return null;
}

bool _matches(Element? element, Element wanted) =>
    element != null && element == wanted;

class _UseShorthand extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    void check(TypeAnnotation? returnType, FunctionBody body) {
      if (returnType is! NamedType) return;
      if (body is! ExpressionFunctionBody) return;

      final expression = body.expression.unParenthesized;
      final range = _typePrefixRangeOf(expression, returnType);
      if (range == null || range.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use the shorthand',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(range);
      });
    }

    context.registry.addFunctionDeclaration(
      (node) => check(node.returnType, node.functionExpression.body),
    );
    context.registry.addMethodDeclaration(
      (node) => check(node.returnType, node.body),
    );
  }
}
