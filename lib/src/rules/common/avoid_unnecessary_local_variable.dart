import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-local-variable',
  category: 'common',
  problemMessage: 'This variable is only used to initialize another one, so it '
      'adds a name without adding meaning.',
  correctionMessage: 'Assign the value to the other variable directly.',
  tags: ['correctness', 'maintainability', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a local variable exists only to initialize another local.
///
/// ```dart
/// final temp = compute();
/// final result = temp;
/// ```
/// `temp` is a pointless intermediate: `result` could take the value directly.
///
/// DCM's description also covers locals that are never referenced. That half is
/// left to `avoid-unused-local-variable`, and Dart's own `unused_local_variable`
/// already reports it, so covering it here would put three lints on one
/// declaration.
///
/// Only a reference that forms the *whole* initializer counts. In
/// `final scaled = base * 2` the variable is part of a larger expression and is
/// carrying its own weight.
///
/// No quick-fix is offered: folding the value into the other declaration has to
/// reconcile two type annotations, two names and two sets of modifiers, and which
/// of them to keep is a judgement call.
class AvoidUnnecessaryLocalVariable extends AligRule {
  /// Warns when a local only feeds another local's initializer.
  AvoidUnnecessaryLocalVariable(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addVariableDeclarationStatement((node) {
      // A multi-variable declaration cannot be folded away one name at a time.
      if (node.variables.variables.length != 1) return;

      final variable = node.variables.variables.single;
      if (variable.initializer == null) return;

      final element = variable.declaredFragment?.element;
      if (element == null) return;

      final scope = node.thisOrAncestorOfType<FunctionBody>();
      if (scope == null) return;

      final references = _referencesTo(element, scope);
      if (references.length != 1) return;

      if (!_isWholeInitializerOfLocal(references.single)) return;

      reporter.atNode(variable, code);
    });
  }
}

/// Every identifier in [scope] that resolves to [element].
List<SimpleIdentifier> _referencesTo(Element element, FunctionBody scope) {
  final visitor = _ReferenceCollector(element);
  scope.accept(visitor);

  return visitor.references;
}

/// Whether [reference] is the entire initializer of a local declaration.
bool _isWholeInitializerOfLocal(SimpleIdentifier reference) {
  final parent = reference.parent;
  if (parent is! VariableDeclaration) return false;
  if (parent.initializer != reference) return false;

  return parent.parent?.parent is VariableDeclarationStatement;
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  _ReferenceCollector(this._element);

  final Element _element;
  final references = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // The declaration's own name is not a reference to it.
    if (node.parent is VariableDeclaration &&
        (node.parent! as VariableDeclaration).name == node.token) {
      return;
    }
    if (node.element == _element) references.add(node);
  }
}
