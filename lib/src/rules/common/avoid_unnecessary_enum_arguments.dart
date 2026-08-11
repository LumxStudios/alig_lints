import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-enum-arguments',
  category: 'common',
  problemMessage: 'This empty argument list can be omitted.',
  correctionMessage: 'Remove the parentheses.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when an enum constant carries an empty argument list.
///
/// `enum Plain { first(), second() }` is `enum Plain { first, second }`.
///
/// Deliberately not reported:
/// - Constants naming a constructor, such as `fromInt.of(1)`. There the argument
///   list is part of the syntax and cannot be dropped even when empty.
/// - Constants with type arguments, where the parentheses are not the only thing
///   present.
class AvoidUnnecessaryEnumArguments extends AligRule {
  /// Warns when an enum constant has an empty argument list.
  AvoidUnnecessaryEnumArguments(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addEnumConstantDeclaration((node) {
      final arguments = _removableArgumentsOf(node);
      if (arguments == null) return;

      reporter.atNode(arguments, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveEmptyArguments()];
}

/// The empty argument list that can be dropped from [node], or `null`.
ArgumentList? _removableArgumentsOf(EnumConstantDeclaration node) {
  final arguments = node.arguments;
  if (arguments == null) return null;
  if (arguments.constructorSelector != null) return null;
  if (arguments.typeArguments != null) return null;
  if (arguments.argumentList.arguments.isNotEmpty) return null;

  return arguments.argumentList;
}

class _RemoveEmptyArguments extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addEnumConstantDeclaration((node) {
      final arguments = _removableArgumentsOf(node);
      if (arguments == null) return;
      if (arguments.sourceRange != diagnostic.sourceRange) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the parentheses',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(arguments.sourceRange);
      });
    });
  }
}
