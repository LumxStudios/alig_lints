import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'check-for-equals-in-render-object-setters',
  category: 'flutter',
  problemMessage: 'This setter marks the render object dirty even when the value '
      'has not changed, so an unchanged assignment costs a layout or a repaint.',
  correctionMessage: 'Return early when the new value equals the current one.',
  tags: ['performance', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `RenderObject` setter does not compare before invalidating.
///
/// ```dart
/// set width(double value) {
///   _width = value;
///   markNeedsLayout();
/// }
/// ```
/// A parent widget's `updateRenderObject` assigns every property on every
/// rebuild, whether or not it changed. Without the comparison each of those
/// assignments schedules a layout pass, so a rebuild triggered by something
/// unrelated re-lays out this subtree for nothing. The guard is what makes the
/// assignment cheap:
///
/// ```dart
/// if (_width == value) return;
/// ```
///
/// Reported for a setter in a `RenderObject` subclass whose body calls one of the
/// `markNeeds…` methods but contains no `==` or `!=` comparison. Both shapes of
/// guard count — an early `return` and an `if` wrapping the whole body.
///
/// A setter that does not invalidate anything is not reported: without a
/// `markNeeds…` call there is no cost to avoid.
///
/// No quick-fix is offered. The comparison needs the backing field's name, which
/// is a guess from the setter's name in the common case and wrong whenever the
/// class stores the value somewhere else — and a wrong guard would silently stop
/// the render object updating at all.
class CheckForEqualsInRenderObjectSetters extends AligRule {
  /// Warns when a render object setter invalidates unconditionally.
  CheckForEqualsInRenderObjectSetters(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (!node.isSetter) return;

      final owner = node.parent;
      if (owner is! ClassDeclaration) return;
      if (!_isRenderObject(owner)) return;

      final visitor = _SetterBodyInspector();
      node.body.accept(visitor);
      if (!visitor.invalidates || visitor.compares) return;

      reporter.atToken(node.name, code);
    });
  }
}

bool _isRenderObject(ClassDeclaration node) => hasFlutterSupertype(
      node.declaredFragment?.element,
      'RenderObject',
      'rendering/object.dart',
    );

/// Looks for the two things that decide this rule: an invalidation call, and any
/// equality comparison.
class _SetterBodyInspector extends RecursiveAstVisitor<void> {
  bool invalidates = false;
  bool compares = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name.startsWith('markNeeds')) invalidates = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.lexeme;
    if (operator == '==' || operator == '!=') compares = true;
    super.visitBinaryExpression(node);
  }
}
