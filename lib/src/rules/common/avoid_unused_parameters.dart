import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unused-parameters',
  category: 'common',
  problemMessage: 'The body never reads this parameter, so callers are asked for '
      'something nothing uses.',
  correctionMessage: 'Remove it, or name it _ to say it is ignored on purpose.',
  tags: ['unused-code', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a function or method never reads one of its parameters.
///
/// ```dart
/// int counted(int value, int ignored) => value * 2;
/// ```
/// Every caller computes and passes something the body throws away. Worse, the
/// signature is a claim about what the function depends on, and this one is wrong —
/// so a reader looking for where `ignored` matters finds nothing and has to conclude
/// they missed it.
///
/// **Constructors go to the built-in `avoid_unused_constructor_parameters`**, enabled
/// in `lib/dart_lints.yaml`. Measured: that lint covers constructors and nothing else,
/// which is exactly what leaves functions and methods to this rule.
///
/// Two exclusions:
///
/// - **overrides**, where the signature comes from the supertype and the unused
///   parameter is not this declaration's choice;
/// - **wildcard names** — `_`, `__` — which are how Dart says a parameter is ignored
///   deliberately, and the correction message points at.
///
/// No quick-fix is offered: removing a parameter breaks every call that passes one, and
/// those calls are not visible from the declaration.
class AvoidUnusedParameters extends AligRule {
  /// Warns when a parameter is never read.
  AvoidUnusedParameters(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      final expression = node.functionExpression;
      _report(expression.parameters, expression.body, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      // An inherited signature is not this method's to change.
      if (node.declaredFragment?.element.metadata.hasOverride ?? true) return;

      _report(node.parameters, node.body, reporter);
    });
  }

  void _report(
    FormalParameterList? parameters,
    FunctionBody body,
    DiagnosticReporter reporter,
  ) {
    if (parameters == null) return;
    if (body is EmptyFunctionBody) return;

    final read = _elementsReadIn(body);

    for (final parameter in parameters.parameters) {
      final name = parameter.name;
      final element = parameter.declaredFragment?.element;
      if (name == null || element == null) continue;
      // A field formal assigns the field, which is a use.
      if (element.isInitializingFormal || element.isSuperFormal) continue;
      if (_isWildcard(name.lexeme)) continue;
      if (read.contains(element)) continue;

      reporter.atToken(name, code);
    }
  }
}

bool _isWildcard(String name) =>
    name.isNotEmpty && name.split('').every((character) => character == '_');

/// The elements [body] reads anywhere inside it.
Set<Element> _elementsReadIn(FunctionBody body) {
  final visitor = _ReferenceCollector();
  body.accept(visitor);

  return visitor.elements;
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  final elements = <Element>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element != null) elements.add(element);
  }
}
