import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-recursive-widget-calls',
  category: 'flutter',
  problemMessage: 'This widget builds itself, so building it once builds it '
      'forever.',
  correctionMessage: 'Build a different widget, or move the recursion behind a '
      'condition that ends it.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a widget's `build` method constructs the same widget.
///
/// ```dart
/// class Direct extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) => Direct();
/// }
/// ```
/// Building `Direct` builds another `Direct`, unconditionally. The app does not
/// render a wrong layout — it runs out of stack, and the trace is thousands of
/// identical frames with nothing pointing at the line that started it.
///
/// A `State`'s `build` is checked against its widget too, so
/// `_StatefulState.build` returning `Stateful()` counts.
///
/// **Only unconditional recursion is reported.** A `build` that constructs itself
/// inside an `if`, a ternary, or a collection `if` is how recursive trees are
/// written, and those terminate; reporting them would fire on every tree widget.
///
/// No quick-fix is offered: whether the repair is a different widget or a base
/// case is a question about what the widget is for.
class AvoidRecursiveWidgetCalls extends AligRule {
  /// Warns when a widget's build constructs the same widget unconditionally.
  AvoidRecursiveWidgetCalls(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'build') return;

      final built = _widgetBuiltBy(node);
      if (built == null) return;

      final visitor = _SelfConstructionCollector(built);
      node.body.accept(visitor);
      for (final creation in visitor.creations) {
        reporter.atNode(creation, code);
      }
    });
  }
}

/// The widget class whose tree this `build` produces: the enclosing class when it
/// is a widget, or the widget a `State` belongs to.
InterfaceElement? _widgetBuiltBy(MethodDeclaration build) {
  final owner = build.parent;
  if (owner is! ClassDeclaration) return null;

  final element = owner.declaredFragment?.element;
  if (element == null) return null;
  if (isWidgetSubclass(element)) return element;
  if (!isStateSubclass(element)) return null;

  // State<MyWidget> — the widget is the type argument.
  for (final supertype in element.allSupertypes) {
    if (supertype.element.name != 'State') continue;

    final argument = supertype.typeArguments.singleOrNull;
    if (argument is InterfaceType) return argument.element;
  }

  return null;
}

/// Collects unconditional constructions of one widget class.
class _SelfConstructionCollector extends RecursiveAstVisitor<void> {
  _SelfConstructionCollector(this._widget);

  final InterfaceElement _widget;
  final creations = <InstanceCreationExpression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type is InterfaceType && type.element == _widget) {
      creations.add(node);
    }
    super.visitInstanceCreationExpression(node);
  }

  // A branch is how recursive trees terminate, so anything conditional is left
  // alone.
  @override
  void visitIfStatement(IfStatement node) {}

  @override
  void visitConditionalExpression(ConditionalExpression node) {}

  @override
  void visitIfElement(IfElement node) {}

  @override
  void visitSwitchStatement(SwitchStatement node) {}

  @override
  void visitSwitchExpression(SwitchExpression node) {}

  // A closure runs later, if at all — a builder callback is not this build.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
