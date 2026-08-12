import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unused-generics',
  category: 'common',
  problemMessage: 'Nothing in this declaration uses the type parameter, so callers '
      'have to supply a type that changes nothing.',
  correctionMessage: 'Remove the type parameter.',
  tags: ['unused-code', 'readability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a function or method declares a type parameter it never uses.
///
/// ```dart
/// void unused<T>() => print('nothing');
/// ```
/// A type parameter that appears nowhere else cannot be inferred, so every caller
/// either writes it out — `unused<int>()`, choosing a type that has no effect — or
/// leaves it out and gets `dynamic`. Either way the signature asks a question with no
/// consequence, and readers spend a moment looking for the answer.
///
/// The parameter counts as used if it appears anywhere in the declaration: another
/// parameter's type, the return type, a bound, or the body — `final values = <T>[]`
/// is a use.
///
/// A class's own type parameters are not this rule's business; only the ones a
/// function or method declares itself. So `Holder<T>.ignores<U>()` is reported for `U`
/// and says nothing about `T`.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// A type parameter that cannot be inferred is one callers may be passing explicitly,
/// and removing it from the declaration makes every one of those calls a compile error.
/// The repair has to happen at the calls first, which is not an edit a single-file fix
/// can make.
class AvoidUnusedGenerics extends AligRule {
  /// Warns when a declared type parameter is never used.
  AvoidUnusedGenerics(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _report(node, node.functionExpression.typeParameters, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _report(node, node.typeParameters, reporter, code: code);
    });
  }

  void _report(
    AstNode declaration,
    TypeParameterList? parameters,
    DiagnosticReporter reporter, {
    LintCode? code,
  }) {
    if (parameters == null) return;

    final used = _typeNamesUsedIn(declaration, parameters);

    for (final parameter in parameters.typeParameters) {
      if (used.contains(parameter.name.lexeme)) continue;

      reporter.atToken(parameter.name, code ?? this.code);
    }
  }
}

/// Every identifier used as a type anywhere in [declaration], excluding the type
/// parameter names' own declarations.
Set<String> _typeNamesUsedIn(AstNode declaration, TypeParameterList parameters) {
  final visitor = _TypeNameCollector(parameters);
  declaration.accept(visitor);

  return visitor.names;
}

class _TypeNameCollector extends RecursiveAstVisitor<void> {
  _TypeNameCollector(this._declarations);

  final TypeParameterList _declarations;
  final names = <String>{};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    // The declaration of a type parameter is not a use of it; its bound is.
    if (!_declarations.typeParameters.contains(node)) {
      names.add(node.name.lexeme);
    }
    node.bound?.accept(this);
  }
}
