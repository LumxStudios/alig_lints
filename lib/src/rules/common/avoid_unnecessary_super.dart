import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-super',
  category: 'common',
  problemMessage: 'This super reference resolves to what would be reached '
      'without it.',
  correctionMessage: 'Remove the super reference.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns about `super` references that change nothing.
///
/// Two shapes:
/// - `Foo() : super();` — an unnamed, argument-less super constructor call is
///   what Dart inserts anyway.
/// - `super.log(...)` in a class that does not declare `log` itself, where a
///   plain `log(...)` reaches the same member.
///
/// The second case is checked conservatively, because dropping `super.` can
/// change which member runs. It is only reported when the enclosing class both
/// declares no member of that name — otherwise removing the prefix would make the
/// call recursive — and applies no mixins, since a mixin can supply a competing
/// member that the prefix is there to skip past.
class AvoidUnnecessarySuper extends AligRule {
  /// Warns about `super` references that resolve to the same member anyway.
  AvoidUnnecessarySuper(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSuperConstructorInvocation((node) {
      if (!_isRedundantSuperConstructorCall(node)) return;

      reporter.atNode(node, code);
    });

    context.registry.addMethodInvocation((node) {
      if (!_isRedundantSuperPrefix(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveSuper()];
}

bool _isRedundantSuperConstructorCall(SuperConstructorInvocation node) =>
    node.constructorName == null && node.argumentList.arguments.isEmpty;

bool _isRedundantSuperPrefix(MethodInvocation node) {
  if (node.target is! SuperExpression) return false;

  final enclosing = node.thisOrAncestorOfType<ClassDeclaration>();
  if (enclosing == null) return false;

  // A mixin can supply a competing member, which is exactly what the prefix
  // steps past.
  if (enclosing.withClause != null) return false;

  return !_declaresMember(enclosing, node.methodName.name);
}

/// Whether [declaration] itself declares a member called [name].
bool _declaresMember(ClassDeclaration declaration, String name) =>
    declaration.members.any((member) => switch (member) {
          MethodDeclaration(name: final memberName) =>
            memberName.lexeme == name,
          FieldDeclaration(:final fields) =>
            fields.variables.any((variable) => variable.name.lexeme == name),
          _ => false,
        });

class _RemoveSuper extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addSuperConstructorInvocation((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_isRedundantSuperConstructorCall(node)) return;

      final constructor = node.parent;
      if (constructor is! ConstructorDeclaration) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the super call',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(
          _rangeRemovingInitializer(constructor, node, resolver),
        );
      });
    });

    context.registry.addMethodInvocation((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_isRedundantSuperPrefix(node)) return;

      final target = node.target!;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the super prefix',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Takes `super.` out, leaving the invocation.
        fileBuilder.addDeletion(
          SourceRange(target.offset, node.methodName.offset - target.offset),
        );
      });
    });
  }

  /// The range removing [invocation] from [constructor]'s initializer list.
  ///
  /// When it is the only initializer the leading `:` goes too, since an empty
  /// initializer list is not valid syntax.
  SourceRange _rangeRemovingInitializer(
    ConstructorDeclaration constructor,
    SuperConstructorInvocation invocation,
    CustomLintResolver resolver,
  ) {
    if (constructor.initializers.length == 1) {
      final separator = constructor.separator;

      return rangeWithLeadingSpaceBetween(
        separator?.offset ?? invocation.offset,
        invocation.end,
        resolver,
      );
    }

    return rangeRemovingListItem(invocation, resolver);
  }
}
