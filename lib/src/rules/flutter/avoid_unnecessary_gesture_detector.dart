import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-gesture-detector',
  category: 'flutter',
  problemMessage: 'This GestureDetector has no handlers, so it adds a layer to '
      'the tree and responds to nothing.',
  correctionMessage: 'Give it a handler, or remove it and keep the child.',
  tags: ['correctness', 'performance', 'flutter'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `GestureDetector` has no event handlers.
///
/// ```dart
/// GestureDetector(child: Text('a'))
/// ```
/// It participates in hit testing and builds a `RawGestureDetector` underneath,
/// all to do nothing. Usually the handler was removed during a refactor and the
/// wrapper stayed, so the widget now reads as interactive to anyone maintaining it
/// while being inert at run time.
///
/// A handler is any argument whose name begins with `on` — `onTap`,
/// `onLongPress`, `onVerticalDragUpdate` and the rest — so the rule does not need
/// to track the full list as Flutter adds to it. `behavior` and
/// `excludeFromSemantics` do not count: without a handler they configure nothing.
///
/// The fix replaces the whole widget with its child, and is offered only when
/// `child` is the sole argument. With anything else present, deleting the wrapper
/// would silently drop that argument too — even though it does nothing today,
/// removing it is a decision rather than a keystroke.
class AvoidUnnecessaryGestureDetector extends AligRule {
  /// Warns when a `GestureDetector` handles nothing.
  AvoidUnnecessaryGestureDetector(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isHandlerlessDetector(node)) return;

      reporter.atNode(node.constructorName, code);
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithChild()];
}

/// Whether [node] builds a `GestureDetector` with nothing to handle.
bool _isHandlerlessDetector(InstanceCreationExpression node) {
  final type = node.staticType;
  if (type is! InterfaceType) return false;
  if (!hasFlutterSupertype(
    type.element,
    'GestureDetector',
    'widgets/gesture_detector.dart',
  )) {
    return false;
  }

  return !node.argumentList.arguments.any(_isHandler);
}

/// Whether [argument] passes a callback, judged by the parameter's name so that
/// handlers Flutter adds later are covered without listing them.
bool _isHandler(Expression argument) =>
    argument is NamedExpression && argument.name.label.name.startsWith('on');

class _ReplaceWithChild extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.sourceRange != diagnostic.sourceRange) return;
      if (!_isHandlerlessDetector(node)) return;

      final arguments = node.argumentList.arguments;
      final child = arguments.singleOrNull;
      // Anything besides the child would be silently dropped by the rewrite.
      if (child is! NamedExpression || child.name.label.name != 'child') return;

      reporter
          .createChangeBuilder(message: 'Replace with the child', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          child.expression.toSource(),
        );
      });
    });
  }
}
