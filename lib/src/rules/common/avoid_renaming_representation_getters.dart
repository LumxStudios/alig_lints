import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-renaming-representation-getters',
  category: 'common',
  problemMessage: 'This getter only returns the representation field under another '
      'name, so the same value has two names on the same type.',
  correctionMessage: 'Use the representation field\'s name, or rename the field.',
  tags: ['readability', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an extension type getter renames its representation field.
///
/// ```dart
/// extension type Meters(int value) {
///   int get metres => value;
/// }
/// ```
/// Both names are public and both return the same thing, so every reader has to work
/// out whether they differ — and every author has to pick one. The extension type
/// already names its representation field; a second name for it adds a decision
/// without adding a value.
///
/// If `metres` is the better name, the representation field should be called that.
/// That is a change to one line and removes the choice entirely.
///
/// Reported for a getter whose body is exactly the representation field, written as
/// `=> field` or `{ return field; }`. A getter that computes anything — `value * 2`,
/// `text.toUpperCase()` — is doing work and is not reported, and neither is one that
/// happens to share the field's name.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// Both plausible repairs — deleting the getter, or renaming the representation field
/// to match it — change a **public** API: the first breaks every caller of the getter,
/// the second every caller of the field. Which is right depends on which name the
/// callers should be using, and that is not visible from the declaration.
class AvoidRenamingRepresentationGetters extends AligRule {
  /// Warns when a getter is an alias for the representation field.
  AvoidRenamingRepresentationGetters(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExtensionTypeDeclaration((node) {
      final representation = node.representation.fieldName.lexeme;

      for (final member in node.members) {
        if (member is! MethodDeclaration || !member.isGetter) continue;
        if (member.name.lexeme == representation) continue;
        if (_returnedName(member.body) != representation) continue;

        reporter.atToken(member.name, code);
      }
    });
  }
}

/// The name [body] hands straight back, or null when it does anything else.
String? _returnedName(FunctionBody body) {
  final returned = switch (body) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block) => _singleReturnOf(block),
    _ => null,
  };

  final node = returned?.unParenthesized;

  return node is SimpleIdentifier ? node.name : null;
}

Expression? _singleReturnOf(Block block) {
  final statement = block.statements.singleOrNull;

  return statement is ReturnStatement ? statement.expression : null;
}
