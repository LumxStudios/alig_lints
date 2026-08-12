import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'move-variable-closer-to-its-usage',
  category: 'common',
  problemMessage: 'Only one inner block uses this variable, so the work happens on '
      'every path and the value is read on one.',
  correctionMessage: 'Declare it inside the block that uses it.',
  tags: ['readability', 'performance'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a variable is declared in an outer block and used in only one inner one.
///
/// ```dart
/// void run(bool flag) {
///   final message = compute();
///   if (flag) {
///     print(message);
///   }
/// }
/// ```
/// `compute()` runs whether or not the branch is taken, and a reader arriving at the
/// declaration has to carry `message` through the rest of the function before finding out
/// that only one branch wants it. Moving it inside says both things at once: this is where
/// the value is needed, and this is when the work happens.
///
/// Reported when **every** reference to the variable sits in one single inner block. A
/// variable read in the outer block as well, or in two different branches, is declared
/// where it belongs.
///
/// No quick-fix is offered. Moving a declaration into a block is a two-place edit whose
/// result depends on the indentation and the surrounding blank lines, and where the
/// initializer has side effects the move also changes when they happen — which is the
/// point, but it is a change the author should make deliberately.
class MoveVariableCloserToItsUsage extends AligRule {
  /// Warns when a declaration is further out than its only use.
  MoveVariableCloserToItsUsage(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((block) {
      for (final statement in block.statements) {
        if (statement is! VariableDeclarationStatement) continue;

        final variable = statement.variables.variables.singleOrNull;
        final element = variable?.declaredFragment?.element;
        if (variable == null || element == null) continue;

        if (!_allUsesShareOneInnerBlock(block, statement, element)) continue;

        reporter.atToken(variable.name, code);
      }
    });
  }
}

/// Whether every reference to [element] after [declaration] sits in one and the same
/// block nested inside [outer].
bool _allUsesShareOneInnerBlock(
  Block outer,
  Statement declaration,
  Element element,
) {
  final references = _referencesTo(element, outer);
  if (references.isEmpty) return false;

  Block? shared;
  for (final reference in references) {
    final block = _innerBlockOf(reference, outer);
    // A use directly in the outer block means the declaration is already right.
    if (block == null) return false;
    if (shared == null) {
      shared = block;
    } else if (shared != block) {
      return false;
    }
  }

  return true;
}

/// The outermost block between [reference] and [outer], or null when the reference is
/// directly in [outer].
Block? _innerBlockOf(AstNode reference, Block outer) {
  Block? innermost;
  for (var node = reference.parent; node != null; node = node.parent) {
    if (node == outer) break;
    if (node is Block) innermost = node;
  }

  return innermost;
}

List<SimpleIdentifier> _referencesTo(Element element, Block scope) {
  final visitor = _ReferenceCollector(element);
  scope.accept(visitor);

  return visitor.references;
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  _ReferenceCollector(this._element);

  final Element _element;
  final references = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // The declaration's own name is not a use of it.
    final parent = node.parent;
    if (parent is VariableDeclaration && parent.name == node.token) return;
    if (node.element == _element) references.add(node);
  }
}
