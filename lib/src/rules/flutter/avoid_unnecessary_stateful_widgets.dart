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
  name: 'avoid-unnecessary-stateful-widgets',
  category: 'flutter',
  problemMessage: 'This State only builds — it keeps no state and touches no '
      'part of the life cycle — so the widget could be stateless.',
  correctionMessage: 'Convert it to a StatelessWidget.',
  tags: ['maintainability', 'performance'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a `StatefulWidget`'s `State` does nothing a `StatelessWidget`
/// could not.
///
/// ```dart
/// class _PlainState extends State<Plain> {
///   @override
///   Widget build(BuildContext context) => const Text('plain');
/// }
/// ```
/// The pair costs a second class, an element with a longer life cycle, and a
/// reader's attention: `StatefulWidget` announces that something here changes over
/// time, and nothing does. It is usually left over from a widget that used to hold
/// state.
///
/// A `State` is reported only when **all** of these hold: no `setState` call, no
/// lifecycle override besides `build`, and no instance field. Any one of them is
/// evidence the State is earning its place — a field could be a controller, an
/// override could be cleanup, and `setState` is the whole point.
///
/// The check needs the `State` and its widget in the same file, which is how they
/// are almost always written. A `State` in another file is not reported, since the
/// widget's other half is not visible.
///
/// No quick-fix is offered. The conversion moves `build` into the widget, deletes
/// the `State` class and the `createState` override, and rewrites every
/// `widget.foo` to `foo` — a refactor rather than an edit, and one an IDE already
/// offers.
class AvoidUnnecessaryStatefulWidgets extends AligRule {
  /// Warns when a `State` does nothing stateful.
  AvoidUnnecessaryStatefulWidgets(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      final states = <InterfaceElement, ClassDeclaration>{};
      final widgets = <InterfaceElement, ClassDeclaration>{};

      for (final declaration in unit.declarations) {
        if (declaration is! ClassDeclaration) continue;

        final element = declaration.declaredFragment?.element;
        if (element == null) continue;
        if (isStateSubclass(element)) {
          final widget = _widgetOf(element);
          if (widget != null) states[widget] = declaration;
        } else if (isWidgetSubclass(element)) {
          widgets[element] = declaration;
        }
      }

      for (final entry in states.entries) {
        final widget = widgets[entry.key];
        if (widget == null) continue;
        if (!_isPurelyBuilding(entry.value)) continue;

        reporter.atToken(widget.name, code);
      }
    });
  }
}

/// The widget a `State` subclass belongs to, from its `State<T>` type argument.
InterfaceElement? _widgetOf(InterfaceElement state) {
  for (final supertype in state.allSupertypes) {
    if (supertype.element.name != 'State') continue;

    final argument = supertype.typeArguments.singleOrNull;
    if (argument is InterfaceType) return argument.element;
  }

  return null;
}

/// Whether [state] does nothing that requires being a `State`.
bool _isPurelyBuilding(ClassDeclaration state) {
  for (final member in state.members) {
    // A field is state, or a controller that will need disposing.
    if (member is FieldDeclaration && !member.isStatic) return false;
    if (member is! MethodDeclaration) continue;
    // Any lifecycle hook besides build is doing something with the life cycle.
    if (member.name.lexeme != 'build' && _isLifecycleOverride(member)) {
      return false;
    }
  }

  final visitor = _SetStateDetector();
  state.accept(visitor);

  return !visitor.found;
}

/// Whether [method] overrides something, which for a `State` means a lifecycle
/// hook.
bool _isLifecycleOverride(MethodDeclaration method) =>
    method.declaredFragment?.element.metadata.hasOverride ?? false;

class _SetStateDetector extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isSetStateInvocation(node)) found = true;
    super.visitMethodInvocation(node);
  }
}
