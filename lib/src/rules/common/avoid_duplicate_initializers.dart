import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-initializers',
  category: 'common',
  problemMessage: 'This variable is initialized with the same expression as an '
      'earlier variable in the same scope.',
  correctionMessage: 'Reuse the earlier variable instead of recomputing its '
      'value.',
  tags: ['correctness', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `final` variable repeats the initializer of an earlier variable
/// in the same block.
///
/// Catches side-effect-free, non-literal initializers, such as two variables
/// both initialized to `user.name`. One of them should be reused.
///
/// Deliberately not caught, because it is not clear these are in scope for the
/// rule and including them would produce noise:
/// - Literal initializers. `final zero = 0; final origin = 0;` names the same
///   constant twice, which is ordinary.
/// - Initializers containing an invocation, cascade or increment. Calling
///   something twice may well be intended, and the two calls need not produce
///   the same value.
/// - Variables in different blocks, even when one encloses the other. Only
///   declarations sharing an immediately enclosing block are compared.
///
/// See `doc/LIMITATIONS.md`.
class AvoidDuplicateInitializers extends AligRule {
  /// Warns when a variable repeats an earlier variable's initializer.
  AvoidDuplicateInitializers(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      final seen = <String, VariableDeclaration>{};

      for (final statement in node.statements) {
        if (statement is! VariableDeclarationStatement) continue;

        final isFinal = statement.variables.isFinal;

        for (final variable in statement.variables.variables) {
          final initializer = variable.initializer;
          if (initializer == null) continue;
          if (!_isComparable(initializer)) continue;

          final key = canonicalize(initializer);

          // Only a `final` declaration is reported, but any earlier declaration
          // counts as the one to reuse.
          if (seen.containsKey(key)) {
            if (isFinal) reporter.atNode(variable, code);
            continue;
          }
          seen[key] = variable;
        }
      }
    });
  }

  /// Whether [expression] is worth comparing: not a literal, and safe to
  /// evaluate only once.
  bool _isComparable(Expression expression) {
    if (hasSideEffects(expression)) return false;

    return switch (expression.unParenthesized) {
      Literal() => false,
      _ => true,
    };
  }
}
