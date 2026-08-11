import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-reassignment',
  category: 'common',
  problemMessage: 'This value is overwritten before it is ever read.',
  correctionMessage: 'Remove this assignment, or use the value before '
      'reassigning.',
  tags: ['correctness', 'maintainability', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a value is written to a variable and then replaced before being
/// read.
///
/// ```dart
/// var value = 1;
/// value = 2;
/// ```
/// The `1` never reaches anything — usually a leftover from an edit, sometimes a
/// sign that the second assignment was meant to be conditional.
///
/// Both a declaration's initializer and a plain assignment can be the dead write.
/// Scanning forward stops as soon as the variable is read, or as soon as control
/// flow appears, since a conditional reassignment leaves the first value
/// reachable.
///
/// Compound assignments — `value += 1`, `value = value + 1` — read the old value,
/// so they end the scan rather than triggering it.
///
/// No quick-fix is offered: the dead write's right-hand side may itself do work
/// worth keeping, and whether the fix is to delete the write or to make the
/// second one conditional depends on intent.
class AvoidUnnecessaryReassignment extends AligRule {
  /// Warns when a write is overwritten before being read.
  AvoidUnnecessaryReassignment(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      for (var index = 0; index < node.statements.length; index++) {
        final write = _writeIn(node.statements[index]);
        if (write == null) continue;

        if (_isOverwrittenBeforeRead(node, index + 1, write.target)) {
          reporter.atNode(write.reportOn, code);
        }
      }
    });
  }
}

/// A write to a variable, and the node to report if it turns out to be dead.
class _Write {
  const _Write(this.target, this.reportOn);

  final Element target;
  final AstNode reportOn;
}

/// [statement] as a write whose value does not depend on the old one.
_Write? _writeIn(Statement statement) {
  if (statement is VariableDeclarationStatement) {
    final variables = statement.variables.variables;
    if (variables.length != 1) return null;

    final variable = variables.single;
    final initializer = variable.initializer;
    final element = variable.declaredFragment?.element;
    if (initializer == null || element == null) return null;
    if (_reads(initializer, element)) return null;

    return _Write(element, variable);
  }

  if (statement is ExpressionStatement) {
    final expression = statement.expression;
    if (expression is! AssignmentExpression) return null;
    if (expression.operator.lexeme != '=') return null;
    if (expression.leftHandSide is! SimpleIdentifier) return null;

    final element = expression.writeElement;
    if (element == null) return null;
    // Only locals: a field could be read by anything in between.
    if (element is! LocalVariableElement) return null;
    if (_reads(expression.rightHandSide, element)) return null;

    return _Write(element, expression);
  }

  return null;
}

/// Whether [target] is written again, without being read, at or after [from].
bool _isOverwrittenBeforeRead(Block block, int from, Element target) {
  for (var index = from; index < block.statements.length; index++) {
    final statement = block.statements[index];

    // A read means the earlier value was used after all.
    if (_reads(statement, target)) return false;

    final write = _writeIn(statement);
    if (write != null && write.target == target) return true;

    // Anything else that could branch, loop or jump ends the scan: a write
    // inside it might not happen, which would leave the earlier value reachable.
    if (statement is! ExpressionStatement &&
        statement is! VariableDeclarationStatement) {
      return false;
    }
  }

  return false;
}

/// Whether [node] reads [target] anywhere inside it.
bool _reads(AstNode node, Element target) {
  final visitor = _ReadDetector(target);
  node.accept(visitor);

  return visitor.found;
}

/// Finds reads of an element, ignoring the plain assignment targets that only
/// write it.
class _ReadDetector extends RecursiveAstVisitor<void> {
  _ReadDetector(this._target);

  final Element _target;
  bool found = false;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // `x = ...` writes x; `x += ...` also reads it.
    final isPlainWrite = node.operator.lexeme == '=' &&
        node.leftHandSide is SimpleIdentifier &&
        node.writeElement == _target;

    if (!isPlainWrite) node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == _target) found = true;
  }
}
