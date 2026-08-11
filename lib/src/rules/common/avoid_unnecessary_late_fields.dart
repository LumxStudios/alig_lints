import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-late-fields',
  category: 'common',
  problemMessage: 'Every constructor initializes this field, so late has no '
      'effect.',
  correctionMessage: 'Remove the late keyword.',
  tags: ['correctness', 'assignments', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `late final` field is initialized by every constructor.
///
/// `late` exists to defer initialization. When every constructor supplies the
/// value up front — through a `this.value` parameter or an initializer list entry
/// — nothing is deferred, and the keyword only costs a runtime check.
///
/// Deliberately not reported:
/// - Fields assigned in a constructor *body*. A non-`late` final field cannot be
///   assigned there at all, so `late` is doing real work.
/// - Classes where some constructor leaves the field unset, and classes with no
///   constructor at all, where the field genuinely is initialized later.
/// - Fields with their own initializer, such as `late final x = compute()`, where
///   `late` defers the computation itself.
class AvoidUnnecessaryLateFields extends AligRule {
  /// Warns when `late` on a final field is redundant.
  AvoidUnnecessaryLateFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final constructors =
          node.members.whereType<ConstructorDeclaration>().toList();
      if (constructors.isEmpty) return;

      for (final field in node.members.whereType<FieldDeclaration>()) {
        final lateKeyword = field.fields.lateKeyword;
        if (lateKeyword == null) continue;
        if (!field.fields.isFinal) continue;
        if (field.isStatic) continue;

        for (final variable in field.fields.variables) {
          if (variable.initializer != null) continue;

          final name = variable.name.lexeme;
          final initializedEverywhere = constructors.every(
            (constructor) => _initializesUpFront(constructor, name),
          );
          if (initializedEverywhere) reporter.atToken(lateKeyword, code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveLate()];
}

/// Whether [constructor] gives [name] its value before its body runs.
bool _initializesUpFront(ConstructorDeclaration constructor, String name) {
  // Redirecting constructors delegate initialization to their target.
  final isRedirecting = constructor.initializers
      .whereType<RedirectingConstructorInvocation>()
      .isNotEmpty;
  if (isRedirecting) return true;

  final hasFieldFormal = constructor.parameters.parameters.any((parameter) {
    final notDefault = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;

    return notDefault is FieldFormalParameter &&
        notDefault.name.lexeme == name;
  });
  if (hasFieldFormal) return true;

  return constructor.initializers
      .whereType<ConstructorFieldInitializer>()
      .any((initializer) => initializer.fieldName.name == name);
}

class _RemoveLate extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addFieldDeclaration((node) {
      final lateKeyword = node.fields.lateKeyword;
      if (lateKeyword == null) return;
      if (lateKeyword.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the late keyword',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Deletes `late ` up to the next token, leaving `final int value;`.
        // The range must not extend backwards: the whitespace before `late` is
        // the declaration's indentation.
        fileBuilder.addDeletion(
          SourceRange(
            lateKeyword.offset,
            lateKeyword.next!.offset - lateKeyword.offset,
          ),
        );
      });
    });
  }
}
