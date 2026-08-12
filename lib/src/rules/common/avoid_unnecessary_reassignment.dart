import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

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
/// The fix removes the dead write, and only where the value being discarded is
/// side-effect-free: `var value = compute();` overwritten later is reported without
/// one, because deleting it would delete the call as well.
///
/// For a declaration the fix removes only the **initializer**, not the statement.
/// Deleting `var value = 1;` outright would leave the `value = 2;` below it with
/// nothing declaring `value` — code that does not compile. `var value;` followed by
/// the real assignment does.
///
/// The catalogue also lists this defect as `avoid-unused-assignment`. It is one
/// defect, so there is one rule; see `doc/LIMITATIONS.md`.
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
      for (final dead in _deadWritesIn(node)) {
        reporter.atNode(dead.reportOn, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveDeadWrite()];
}

/// The dead writes among [block]'s own statements.
List<_Write> _deadWritesIn(Block block) {
  final dead = <_Write>[];

  for (var index = 0; index < block.statements.length; index++) {
    final write = _writeIn(block.statements[index]);
    if (write == null) continue;

    if (_isOverwrittenBeforeRead(block, index + 1, write.target)) {
      dead.add(write);
    }
  }

  return dead;
}

class _RemoveDeadWrite extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addBlock((node) {
      for (final dead in _deadWritesIn(node)) {
        if (dead.reportOn.sourceRange != diagnostic.sourceRange) continue;

        final value = _valueOf(dead.reportOn);
        // Deleting a value that does something would delete the something.
        if (value == null || hasSideEffects(value)) continue;

        reporter
            .createChangeBuilder(message: 'Remove the write', priority: 60)
            .addDartFileEdit((builder) {
          builder.addDeletion(_rangeToRemoveFor(dead.reportOn, value, resolver));
        });
      }
    });
  }
}

/// The value a dead write discards.
Expression? _valueOf(AstNode dead) => switch (dead) {
      VariableDeclaration(:final initializer) => initializer,
      AssignmentExpression(:final rightHandSide) => rightHandSide,
      _ => null,
    };

/// What the fix deletes.
///
/// A re-assignment goes whole. A declaration loses only its initializer: removing
/// `var value = 1;` would leave the assignment below it undeclared.
SourceRange _rangeToRemoveFor(
  AstNode dead,
  Expression value,
  CustomLintResolver resolver,
) {
  if (dead is! VariableDeclaration) {
    final statement = dead.thisOrAncestorOfType<Statement>() ?? dead;

    return lineRangeOf(statement, resolver);
  }

  return SourceRange(dead.name.end, value.end - dead.name.end);
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
