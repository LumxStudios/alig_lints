import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-referencing-discarded-variables',
  category: 'common',
  problemMessage: 'This name says the value is being thrown away, and then it is '
      'used.',
  correctionMessage: 'Give it a name that says what it holds.',
  tags: ['readability', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a variable named only with underscores is referenced.
///
/// ```dart
/// void parameters(int first, int __) {
///   print(first + __);
/// }
/// ```
/// An underscore name is the established way of saying "this is required by the
/// signature and I do not care about it". Reading it contradicts that: someone
/// scanning the code sees a discard and skips over the line that depends on it.
///
/// Dart makes `_` a genuine wildcard, so referencing a single underscore is already a
/// compile error. What is left — and what this reports — is `__`, `___` and longer,
/// which the language still treats as ordinary names. Measured: nothing else warns
/// about them.
///
/// Reported for a reference to a local, a parameter or a pattern variable whose name
/// is all underscores. The declaration itself is not reported: declaring a discard is
/// the correct use of the name.
///
/// No quick-fix is offered: the repair is a name, which the rule has no way to
/// choose, and renaming every reference in one edit is what a rename refactor is for.
class AvoidReferencingDiscardedVariables extends AligRule {
  /// Warns when a discarded name is used after all.
  AvoidReferencingDiscardedVariables(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSimpleIdentifier((node) {
      if (!_isAllUnderscores(node.name)) return;
      if (_isDeclaration(node)) return;

      final element = node.element;
      final isDiscardable = element is LocalVariableElement ||
          element is FormalParameterElement ||
          element is PatternVariableElement;
      if (!isDiscardable) return;

      reporter.atNode(node, code);
    });
  }
}

bool _isAllUnderscores(String name) =>
    name.isNotEmpty && name.split('').every((character) => character == '_');

/// Whether [node] is the name being declared rather than a use of it.
bool _isDeclaration(SimpleIdentifier node) {
  final parent = node.parent;

  return parent is VariableDeclaration && parent.name == node.token ||
      parent is FormalParameter && parent.name == node.token ||
      parent is DeclaredVariablePattern && parent.name == node.token;
}
