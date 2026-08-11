import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-nested-shorthands',
  category: 'common',
  problemMessage: 'A shorthand argument inside a shorthand call leaves no type '
      'name on the line to read.',
  correctionMessage: 'Write the inner value out in full.',
  tags: ['maintainability', 'readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a dot shorthand is passed as an argument to another dot shorthand.
///
/// A shorthand takes its meaning from the type the context expects, so
/// `.from(.of(.red, size: .small))` names nothing a reader can follow — every
/// type has to be reconstructed from the signatures.
///
/// One level is the point of the feature and is left alone; only an argument that
/// is itself a shorthand is reported.
class AvoidNestedShorthands extends AligRule {
  /// Warns when shorthands are nested.
  AvoidNestedShorthands(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(AstNode node, ArgumentList arguments) {
      final nested = arguments.arguments.where(_isShorthand).toList();
      if (nested.isEmpty) return;

      reporter.atNode(node, code);
    }

    context.registry.addDotShorthandInvocation(
      (node) => check(node, node.argumentList),
    );
    context.registry.addDotShorthandConstructorInvocation(
      (node) => check(node, node.argumentList),
    );
  }
}

/// Whether [argument] is itself written as a dot shorthand.
bool _isShorthand(Expression argument) {
  final expression =
      argument is NamedExpression ? argument.expression : argument;

  return switch (expression.unParenthesized) {
    DotShorthandInvocation() => true,
    DotShorthandConstructorInvocation() => true,
    DotShorthandPropertyAccess() => true,
    _ => false,
  };
}
