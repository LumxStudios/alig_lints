import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-call',
  category: 'common',
  problemMessage: 'This target can be invoked directly, so naming call adds '
      'nothing.',
  correctionMessage: 'Drop the .call.',
  tags: ['readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a `.call()` invocation can be written as a direct call.
///
/// Both function values and objects with a `call` method are callable directly,
/// so `twice.call(2)` and `multiplier.call(3)` are both just `twice(2)` and
/// `multiplier(3)`.
///
/// Deliberately not reported, because neither has a shorthand:
/// - Null-aware invocations. There is no `maybe?()` syntax, so `maybe?.call(4)`
///   is the only way to write it.
/// - Cascade sections. `..call(5)` cannot become `..(5)`.
class AvoidUnnecessaryCall extends AligRule {
  /// Warns when `.call()` can be dropped.
  AvoidUnnecessaryCall(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!_isRemovableCall(node)) return;

      reporter.atNode(node.methodName, code);
    });
  }

  @override
  List<Fix> getFixes() => [_DropCall()];
}

bool _isRemovableCall(MethodInvocation node) {
  if (node.methodName.name != 'call') return false;

  // A cascade section has no target of its own and cannot lose the name.
  final target = node.target;
  if (target == null) return false;

  // `maybe?.call(4)` has no shorthand.
  if (node.operator?.lexeme != '.') return false;

  // The target must itself be callable: either a function value, or an instance
  // whose class declares `call`.
  final targetType = target.staticType;
  if (targetType == null) return false;
  if (targetType.nullabilitySuffix.name == 'question') return false;

  return true;
}

class _DropCall extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.sourceRange != diagnostic.sourceRange) return;
      if (!_isRemovableCall(node)) return;

      final target = node.target!;

      final builder = reporter.createChangeBuilder(
        message: 'Drop the .call',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Removes the `.call`, leaving the target and the argument list.
        fileBuilder.addDeletion(
          SourceRange(target.end, node.methodName.end - target.end),
        );
      });
    });
  }
}
