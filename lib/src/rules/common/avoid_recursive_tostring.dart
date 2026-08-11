import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-recursive-tostring',
  category: 'common',
  problemMessage: 'This calls the toString it is inside, so the method never '
      'returns and the program dies of a stack overflow.',
  correctionMessage: 'Build the text from the fields, or delegate to '
      'super.toString().',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `toString` method calls itself.
///
/// ```dart
/// @override
/// String toString() => 'Direct: $this';
/// ```
/// Interpolating `this` calls `this.toString()`, which is the method being
/// written, so the call recurses until the stack runs out. The crash arrives
/// wherever the object is first printed — often inside logging or an error path
/// that was supposed to explain a different problem.
///
/// Both spellings are reported: an explicit `toString()` call with no receiver
/// or with `this`, and an interpolation of `this` that calls it implicitly.
///
/// `super.toString()` is not reported. It reaches the inherited implementation
/// rather than this one, and is the normal way to build on the default.
///
/// Recursion through another object is not reported. `'$child'` inside
/// `Node.toString` only loops if `child` is this same node, and whether it can
/// be depends on how the graph is built rather than on anything in the method.
///
/// No quick-fix is offered: the replacement is the text the author meant to
/// produce, which cannot be guessed from the call that replaced it.
class AvoidRecursiveTostring extends AligRule {
  /// Warns when `toString` calls itself directly.
  AvoidRecursiveTostring(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'toString') return;

      final visitor = _SelfCallCollector();
      node.body.accept(visitor);

      for (final call in visitor.calls) {
        reporter.atNode(call, code);
      }
    });
  }
}

/// Collects the expressions inside a `toString` body that re-enter it.
class _SelfCallCollector extends RecursiveAstVisitor<void> {
  final calls = <AstNode>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    // Only a call on this object re-enters; super reaches the inherited one.
    final isSelf = target == null || target is ThisExpression;
    if (isSelf && node.methodName.name == 'toString') calls.add(node);

    super.visitMethodInvocation(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (node.expression is ThisExpression) calls.add(node);

    super.visitInterpolationExpression(node);
  }

  // A closure inside the body may well be handed to something else entirely.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
