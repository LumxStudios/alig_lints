import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-setstate',
  category: 'flutter',
  problemMessage: 'A rebuild is already happening here, so this setState '
      'schedules a second one for state that could just be assigned.',
  correctionMessage: 'Assign the state directly, without setState.',
  tags: ['correctness', 'performance'],
  severity: DiagnosticSeverity.WARNING,
);

/// The lifecycle methods during which a build is already under way or scheduled.
const _buildingMethods = {'initState', 'didUpdateWidget', 'build'};

/// Warns when `setState` is called from a method that is already rebuilding.
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   setState(() => counter = widget.value);
/// }
/// ```
/// `initState` runs immediately before the first build, and `didUpdateWidget`
/// immediately before a rebuild that is already scheduled. `setState` there asks
/// for another one — so the frame does the work twice — and inside `build` it is
/// worse than wasteful: Flutter throws for calling `setState` during a build.
///
/// The assignment on its own is enough. The state is read by the build that is
/// about to happen anyway.
///
/// Reported for a `setState` written directly in one of those three methods, and
/// for one in a **synchronous method of the same class** that they call. That
/// second case is what makes the rule useful — the call is usually one level away,
/// in a `refresh()` helper — and the reason it stops at one class: following the
/// call further would mean tracking the whole program.
///
/// Not reported when the call is reached through an `async` method or a closure.
/// Those run after the current build has finished, which is when `setState` is
/// exactly the right thing to call.
///
/// No quick-fix is offered. Removing the wrapper leaves its body behind, and where
/// the body is a block with several statements the result depends on which of them
/// were meant to be state changes.
class AvoidUnnecessarySetstate extends AligRule {
  /// Warns when `setState` runs during a build that is already happening.
  AvoidUnnecessarySetstate(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!isStateSubclass(node.declaredFragment?.element)) return;

      final methods = _methodsOf(node);
      final reachable = _methodsReachedDuringBuild(methods);

      for (final name in reachable) {
        final method = methods[name];
        if (method == null) continue;

        for (final call in _setStateCallsIn(method)) {
          reporter.atNode(call, code);
        }
      }
    });
  }
}

/// The class's methods by name.
Map<String, MethodDeclaration> _methodsOf(ClassDeclaration node) => {
      for (final member in node.members)
        if (member is MethodDeclaration) member.name.lexeme: member,
    };

/// The names of the methods that run while a build is under way: the lifecycle
/// methods themselves, plus the synchronous ones they call directly.
Set<String> _methodsReachedDuringBuild(
  Map<String, MethodDeclaration> methods,
) {
  final reached = <String>{};
  for (final name in _buildingMethods) {
    final method = methods[name];
    if (method == null) continue;

    reached.add(name);
    // One level only: further than this needs the whole program in view.
    for (final called in _localCallsIn(method)) {
      final target = methods[called];
      // A method that awaits runs after this build, which is when setState is
      // the correct call.
      if (target != null && !target.body.isAsynchronous) reached.add(called);
    }
  }

  return reached;
}

/// The names of methods on the same object called directly by [method].
Set<String> _localCallsIn(MethodDeclaration method) {
  final visitor = _LocalCallCollector();
  method.body.accept(visitor);

  return visitor.names;
}

/// The `setState` calls written directly in [method], outside any closure.
List<MethodInvocation> _setStateCallsIn(MethodDeclaration method) {
  final visitor = _SetStateCollector();
  method.body.accept(visitor);

  return visitor.calls;
}

class _LocalCallCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (target == null || target is ThisExpression) {
      names.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  // A closure runs later, after the build it was created in.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _SetStateCollector extends RecursiveAstVisitor<void> {
  final calls = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isSetStateInvocation(node)) calls.add(node);
    // Walked by hand rather than through super, so that the closure skip below
    // does not also skip the receiver.
    node.target?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
