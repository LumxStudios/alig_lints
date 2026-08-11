import 'package:analyzer/dart/ast/ast.dart';

/// Whether [statement] always leaves the block it sits in, so that nothing after
/// it in that block can run.
///
/// Recognises `return`, `throw`, `break`, `continue`, `rethrow`, a call to a
/// function whose return type is `Never`, a block whose last statement always
/// exits, and an `if` whose then and else branches both always exit.
///
/// Returns `false` for anything it cannot prove, including `try` statements,
/// where a `finally` or a caught exception can resume the normal path. Callers
/// rely on this being conservative: a wrong `true` would let a fix delete
/// reachable code.
bool alwaysExits(Statement statement) => switch (statement) {
      ReturnStatement() => true,
      BreakStatement() => true,
      ContinueStatement() => true,
      ExpressionStatement(:final expression) => _expressionExits(expression),
      Block(:final statements) =>
        statements.isNotEmpty && alwaysExits(statements.last),
      IfStatement(:final thenStatement, :final elseStatement) =>
        elseStatement != null &&
            alwaysExits(thenStatement) &&
            alwaysExits(elseStatement),
      _ => false,
    };

bool _expressionExits(Expression expression) {
  if (expression is ThrowExpression || expression is RethrowExpression) {
    return true;
  }

  // A function declared to return `Never` cannot come back.
  final returnType = switch (expression) {
    MethodInvocation() => expression.staticInvokeType,
    FunctionExpressionInvocation() => expression.staticInvokeType,
    _ => null,
  };

  return returnType != null && returnType.getDisplayString().endsWith('Never');
}
