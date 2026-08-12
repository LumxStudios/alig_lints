import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'consistent-update-render-object',
  category: 'flutter',
  problemMessage: 'createRenderObject sets properties that updateRenderObject '
      'does not, so those keep their first value for the widget\'s whole life.',
  correctionMessage: 'Set the same properties in updateRenderObject.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `updateRenderObject` does not set everything `createRenderObject`
/// does.
///
/// ```dart
/// @override
/// RenderObject createRenderObject(BuildContext context) =>
///     _Box()..width = width..height = height;
///
/// @override
/// void updateRenderObject(BuildContext context, RenderObject renderObject) {
///   (renderObject as _Box).width = width;   // height never changes again
/// }
/// ```
/// `createRenderObject` runs once. Every rebuild after that goes through
/// `updateRenderObject`, so a property set only in the first is frozen at whatever
/// it was when the widget first appeared. The widget looks correct until something
/// changes that property, and then it silently does not move — no error, no
/// warning, and nothing in the widget that suggests where to look.
///
/// A missing `updateRenderObject` altogether is reported on
/// `createRenderObject`: the properties it sets can then never change.
///
/// Properties are compared by name, from assignments in each method — whether
/// written as a cascade or as separate statements. Constructor arguments are not
/// counted: a value passed to the render object's constructor may be one it cannot
/// accept later, and demanding a setter for it would be wrong.
///
/// No quick-fix is offered. Copying the assignments across needs the cast or the
/// local that `updateRenderObject` uses to reach the render object, and where the
/// method does not exist yet the whole method would have to be written.
class ConsistentUpdateRenderObject extends AligRule {
  /// Warns when the two render-object methods disagree.
  ConsistentUpdateRenderObject(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!hasFlutterSupertype(
        node.declaredFragment?.element,
        'RenderObjectWidget',
        'widgets/framework.dart',
      )) {
        return;
      }

      final create = _methodNamed(node, 'createRenderObject');
      if (create == null) return;

      final set = _assignedPropertyNamesIn(create);
      if (set.isEmpty) return;

      final update = _methodNamed(node, 'updateRenderObject');
      if (update == null) {
        // Nothing will ever change these again.
        reporter.atToken(create.name, code);

        return;
      }

      if (set.difference(_assignedPropertyNamesIn(update)).isEmpty) return;

      reporter.atToken(update.name, code);
    });
  }
}

MethodDeclaration? _methodNamed(ClassDeclaration node, String name) {
  for (final member in node.members) {
    if (member is MethodDeclaration && member.name.lexeme == name) return member;
  }

  return null;
}

/// The names of the properties [method] assigns, from cascades and from plain
/// assignments alike.
Set<String> _assignedPropertyNamesIn(MethodDeclaration method) {
  final visitor = _AssignedPropertyCollector();
  method.body.accept(visitor);

  return visitor.names;
}

class _AssignedPropertyCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.leftHandSide;
    final name = switch (target) {
      PropertyAccess(:final propertyName) => propertyName.name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      SimpleIdentifier(:final name) => name,
      _ => null,
    };
    if (name != null) names.add(name);

    super.visitAssignmentExpression(node);
  }
}
