import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/mutation_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unreachable-for-loop',
  category: 'common',
  problemMessage: 'The enclosing condition establishes that this collection is '
      'empty, so the loop body never runs.',
  correctionMessage: 'Correct the condition, or remove the loop.',
  tags: ['correctness', 'collections', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an enclosing `if` makes a `for-in` loop unreachable.
///
/// `if (items.isEmpty) { for (final item in items) ... }` never enters the body;
/// the condition is usually inverted by mistake.
///
/// Both directions are covered: an emptiness test guarding the `then` branch, and
/// a non-emptiness test whose `else` branch holds the loop.
///
/// A branch that fills the collection first is not reported. Two things count as
/// filling it, both checked position-insensitively so that anything anywhere in
/// the branch is enough to keep the rule quiet:
/// - rebinding the variable, which `isMutatedWithin` detects;
/// - calling any method on it. `items.add(1)` mutates the object without touching
///   the variable, so the assignment-based check alone would miss it, and every
///   call is treated as potentially filling rather than trying to know which
///   methods mutate.
class AvoidUnreachableForLoop extends AligRule {
  /// Warns when a for-in loop cannot be reached.
  AvoidUnreachableForLoop(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addForStatement((node) {
      final parts = node.forLoopParts;
      if (parts is! ForEachParts) return;

      final iterable = parts.iterable;

      for (final branch in _enclosingBranches(node)) {
        final impliesEmpty = _emptinessAssertedBy(
          branch.statement.expression,
          iterable,
        );
        if (impliesEmpty == null) continue;

        // In the then branch the condition holds; in the else branch it does not.
        final isEmptyHere = branch.isThen ? impliesEmpty : !impliesEmpty;
        if (!isEmptyHere) continue;

        if (_couldFill(branch.body, iterable)) return;

        reporter.atNode(node, code);

        return;
      }
    });
  }
}

/// Whether [body] might leave [iterable] non-empty by the time the loop runs.
bool _couldFill(Statement body, Expression iterable) {
  if (isMutatedWithin(body, iterable)) return true;

  final visitor = _CallOnIterableDetector(iterable);
  body.accept(visitor);

  return visitor.found;
}

/// Finds any method called on the iterable.
class _CallOnIterableDetector extends RecursiveAstVisitor<void> {
  _CallOnIterableDetector(this._iterable);

  final Expression _iterable;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (target != null && areEquivalent(target, _iterable)) found = true;
    super.visitMethodInvocation(node);
  }
}

/// An enclosing `if` and which of its branches contains the loop.
class _Branch {
  const _Branch(this.statement, this.body, {required this.isThen});

  final IfStatement statement;
  final Statement body;
  final bool isThen;
}

/// The enclosing `if` branches containing [node], innermost first.
List<_Branch> _enclosingBranches(AstNode node) {
  final result = <_Branch>[];

  AstNode? child = node;
  var parent = node.parent;
  while (parent != null) {
    if (parent is IfStatement) {
      if (parent.thenStatement == child) {
        result.add(_Branch(parent, parent.thenStatement, isThen: true));
      } else if (parent.elseStatement == child) {
        result.add(_Branch(parent, parent.elseStatement!, isThen: false));
      }
    }
    child = parent;
    parent = parent.parent;
  }

  return result;
}

/// Whether [condition] says [iterable] is empty (`true`), says it is not
/// (`false`), or says nothing about it (`null`).
bool? _emptinessAssertedBy(Expression condition, Expression iterable) {
  final node = condition.unParenthesized;

  if (node is PrefixExpression && node.operator.lexeme == '!') {
    final inner = _emptinessAssertedBy(node.operand, iterable);

    return inner == null ? null : !inner;
  }

  if (node is PropertyAccess || node is PrefixedIdentifier) {
    final target = node is PropertyAccess ? node.target : null;
    final propertyName = switch (node) {
      PropertyAccess(:final propertyName) => propertyName.name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      _ => null,
    };
    final receiver = target ?? (node as PrefixedIdentifier).prefix;
    if (!areEquivalent(receiver, iterable)) return null;

    return switch (propertyName) {
      'isEmpty' => true,
      'isNotEmpty' => false,
      _ => null,
    };
  }

  if (node is BinaryExpression) return _lengthComparison(node, iterable);

  return null;
}

/// Reads `items.length == 0` and its relatives.
bool? _lengthComparison(BinaryExpression node, Expression iterable) {
  final left = node.leftOperand.unParenthesized;
  final right = node.rightOperand.unParenthesized;

  final lengthOnTheLeft = _isLengthOf(left, iterable);
  final literal = lengthOnTheLeft ? right : left;
  if (!lengthOnTheLeft && !_isLengthOf(right, iterable)) return null;
  if (literal is! IntegerLiteral) return null;

  final value = literal.value;
  if (value == null) return null;

  // Normalise so the comparison always reads `length <op> value`.
  final operator = lengthOnTheLeft
      ? node.operator.lexeme
      : _mirrored(node.operator.lexeme);

  return switch (operator) {
    '==' when value == 0 => true,
    '!=' when value == 0 => false,
    '<' when value <= 1 => true,
    '<=' when value == 0 => true,
    '>' when value == 0 => false,
    '>=' when value == 1 => false,
    _ => null,
  };
}

String _mirrored(String operator) => switch (operator) {
      '<' => '>',
      '>' => '<',
      '<=' => '>=',
      '>=' => '<=',
      _ => operator,
    };

/// Whether [expression] is `iterable.length`.
bool _isLengthOf(Expression expression, Expression iterable) {
  final node = expression.unParenthesized;

  if (node is PropertyAccess) {
    final target = node.target;

    return node.propertyName.name == 'length' &&
        target != null &&
        areEquivalent(target, iterable);
  }
  if (node is PrefixedIdentifier) {
    return node.identifier.name == 'length' &&
        areEquivalent(node.prefix, iterable);
  }

  return false;
}
