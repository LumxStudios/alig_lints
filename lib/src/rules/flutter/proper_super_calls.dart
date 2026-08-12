import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'proper-super-calls',
  category: 'flutter',
  problemMessage: 'This super call is in the wrong place: initState must call '
      'super first, and dispose must call it last.',
  correctionMessage: 'Move the super call to the start of initState or the end '
      'of dispose.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `super.initState` or `super.dispose` is called out of order.
///
/// ```dart
/// @override
/// void dispose() {
///   super.dispose();
///   controller.dispose();   // after the State is already torn down
/// }
/// ```
/// The order is not a convention, it is what the framework requires.
/// `super.initState` sets up the machinery the rest of your `initState` uses, so it
/// goes first; `super.dispose` tears that machinery down, so anything of yours
/// that needs it has to run before. Getting either backwards produces failures
/// away from the cause — a listener that never detaches, an assertion in a later
/// frame — and Flutter's own assertions only catch some of them.
///
/// Reported when `super.initState()` is not the first statement, or
/// `super.dispose()` is not the last.
///
/// The fix moves the call, using the same line-range handling as the other
/// statement-moving fixes in this package so the surrounding blank lines come out
/// right.
class ProperSuperCalls extends AligRule {
  /// Warns when a lifecycle super call is in the wrong position.
  ProperSuperCalls(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      final misplaced = _misplacedSuperCallIn(node);
      if (misplaced == null) return;

      reporter.atNode(misplaced, code);
    });
  }

  @override
  List<Fix> getFixes() => [_MoveSuperCall()];
}

/// The `super` call that is in the wrong position, or null when the order is fine.
Statement? _misplacedSuperCallIn(MethodDeclaration node) {
  final name = node.name.lexeme;
  if (name != 'initState' && name != 'dispose') return null;

  final owner = node.parent;
  if (owner is! ClassDeclaration) return null;
  if (!isStateSubclass(owner.declaredFragment?.element)) return null;

  final body = node.body;
  if (body is! BlockFunctionBody) return null;

  final statements = body.block.statements;
  if (statements.length < 2) return null;

  final call = _indexOfSuperCall(statements, name);
  if (call == null) return null;

  final expected = name == 'initState' ? 0 : statements.length - 1;

  return call == expected ? null : statements[call];
}

/// The position of `super.<name>()` among [statements], or null when absent.
int? _indexOfSuperCall(List<Statement> statements, String name) {
  for (var i = 0; i < statements.length; i++) {
    final statement = statements[i];
    if (statement is! ExpressionStatement) continue;

    final expression = statement.expression;
    if (expression is! MethodInvocation) continue;
    if (expression.target is! SuperExpression) continue;
    if (expression.methodName.name == name) return i;
  }

  return null;
}

class _MoveSuperCall extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodDeclaration((node) {
      final misplaced = _misplacedSuperCallIn(node);
      if (misplaced == null) return;
      if (misplaced.sourceRange != diagnostic.sourceRange) return;

      final body = node.body as BlockFunctionBody;
      final statements = body.block.statements;
      final toStart = node.name.lexeme == 'initState';
      // Where the call has to end up: before the first statement, or after the
      // last one that is not the call itself.
      final anchor = toStart ? statements.first : statements.last;
      final indent = indentationOf(anchor, resolver);
      final call = misplaced.toSource();

      reporter
          .createChangeBuilder(
            message: toStart
                ? 'Move the super call to the start'
                : 'Move the super call to the end',
            priority: 60,
          )
          .addDartFileEdit((builder) {
        builder
          ..addDeletion(
            lineRangeOf(misplaced, resolver, absorbFollowingBlankLines: true),
          )
          ..addSimpleInsertion(
            toStart ? lineRangeOf(anchor, resolver).offset : anchor.end,
            toStart ? '$indent$call\n' : '\n$indent$call',
          );
      });
    });
  }
}
