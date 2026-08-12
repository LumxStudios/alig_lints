import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'use-closest-build-context',
  category: 'flutter',
  problemMessage: 'A nearer BuildContext is in scope here, and this one points at '
      'a different place in the tree.',
  correctionMessage: 'Use the closest BuildContext.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an outer `BuildContext` is used where a closer one is in scope.
///
/// ```dart
/// Builder(
///   builder: (innerContext) => Text(MediaQuery.sizeOf(context).width.toString()),
/// )
/// ```
/// A `BuildContext` is a position in the widget tree, not a handle on the app. The
/// outer `context` sits above the `Builder`, so a lookup through it finds a
/// different ancestor — or misses one the `Builder` was added to provide. Using it
/// also registers the *outer* widget as the dependent, so the rebuild happens at
/// the wrong level.
///
/// This is the failure mode `Theme.of` and `MediaQuery.of` are most often blamed
/// for: the value looks right during development and turns out wrong once something
/// is inserted between the two contexts.
///
/// Reported when a `BuildContext` reference resolves to a parameter that is *not*
/// the one declared by the closest enclosing function that has a `BuildContext`
/// parameter.
///
/// The fix substitutes the closer parameter's name. It is a rename within one
/// expression, and the closer context is by definition in scope there.
class UseClosestBuildContext extends AligRule {
  /// Warns when a farther `BuildContext` is used than necessary.
  UseClosestBuildContext(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSimpleIdentifier((node) {
      if (_closerContextFor(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseCloserContext()];
}

/// The name of a nearer `BuildContext` in scope at [node], or null when [node] is
/// not a farther-than-necessary context reference.
String? _closerContextFor(SimpleIdentifier node) {
  if (!isBuildContext(node.staticType)) return null;

  final referenced = node.element;
  if (referenced is! FormalParameterElement) return null;
  // The declaration's own name is not a use of it.
  if (node.parent is FormalParameter) return null;

  for (var current = node.parent; current != null; current = current.parent) {
    final parameters = switch (current) {
      FunctionExpression(:final parameters) => parameters,
      MethodDeclaration(:final parameters) => parameters,
      _ => null,
    };
    if (parameters == null) continue;

    final closest = _buildContextParameterOf(parameters);
    // The first function that has one settles it, whichever way.
    if (closest == null) continue;

    return closest.declaredFragment?.element == referenced
        ? null
        : closest.name?.lexeme;
  }

  return null;
}

/// The `BuildContext` parameter of [parameters], or null when it has none.
FormalParameter? _buildContextParameterOf(FormalParameterList parameters) {
  for (final parameter in parameters.parameters) {
    final element = parameter.declaredFragment?.element;
    if (element != null && isBuildContext(element.type)) return parameter;
  }

  return null;
}

class _UseCloserContext extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addSimpleIdentifier((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final closer = _closerContextFor(node);
      if (closer == null) return;

      reporter
          .createChangeBuilder(message: 'Use $closer', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, closer);
      });
    });
  }
}
