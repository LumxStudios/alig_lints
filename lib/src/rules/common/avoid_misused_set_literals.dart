import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-misused-set-literals',
  category: 'common',
  problemMessage: 'These braces build a set and discard it; they do not open a '
      'block.',
  correctionMessage: 'Use a block body, with the statements separated by '
      'semicolons.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an arrow body builds a set that nothing receives.
///
/// `void handler() => { log('a'), log('b') };` reads like a block to anyone
/// arriving from a brace-and-semicolon language. It is a set literal: the calls
/// run, the set is built, and it goes straight in the bin.
///
/// Only functions returning `void` are reported, so a function that genuinely
/// produces a set — `Set<int> numbers() => {1, 2};` — is untouched.
///
/// Dart has a built-in warning for this, `unnecessary_set_literal`, but it only
/// examines top-level functions; methods and closures, where most code lives, go
/// unreported. This rule covers all three, and the warning is switched off in
/// `lib/dart_lints.yaml` so the shapes it does catch are not reported twice.
///
/// No quick-fix is offered: turning the literal into a block means replacing
/// commas with semicolons and re-deciding what the body returns, which is more
/// rewriting than a fix should do unattended.
class AvoidMisusedSetLiterals extends AligRule {
  /// Warns when an arrow body is a discarded set literal.
  AvoidMisusedSetLiterals(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(FunctionBody body, DartType? returnType) {
      if (body is! ExpressionFunctionBody) return;

      final literal = body.expression.unParenthesized;
      if (literal is! SetOrMapLiteral || !literal.isSet) return;
      if (returnType is! VoidType) return;

      reporter.atNode(literal, code);
    }

    // A method's body is not wrapped in a FunctionExpression, so registering
    // only that would miss methods — the same blind spot the built-in warning
    // has.
    context.registry.addFunctionExpression(
      (node) => check(node.body, node.declaredFragment?.element.returnType),
    );
    context.registry.addMethodDeclaration(
      (node) => check(node.body, node.declaredFragment?.element.returnType),
    );
  }
}
