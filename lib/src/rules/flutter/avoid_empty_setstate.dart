import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-empty-setstate',
  category: 'flutter',
  problemMessage: 'This setState callback is empty, so it triggers a rebuild '
      'without changing any state.',
  correctionMessage:
      'Update state inside the callback, or remove the setState call.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `setState` callback is empty.
///
/// Catches `setState(() {})` and a block body containing only comments.
///
/// Deliberately not caught: `setState(callback)` where the argument is not a
/// closure, because what the callback does is not visible here.
class AvoidEmptySetstate extends AligRule {
  /// Warns when a `setState` callback is empty.
  AvoidEmptySetstate(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!isSetStateInvocation(node)) return;

      final arguments = node.argumentList.arguments;
      if (arguments.length != 1) return;

      final callback = arguments.first;
      if (callback is! FunctionExpression) return;

      final isEmpty = switch (callback.body) {
        BlockFunctionBody(:final block) => block.statements.isEmpty,
        EmptyFunctionBody() => true,
        _ => false,
      };
      if (isEmpty) reporter.atNode(node, code);
    });
  }
}
