import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/rule_options.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-constant-values',
  category: 'common',
  problemMessage: 'This constant repeats the value of another constant in the '
      'same declaration.',
  correctionMessage: 'Give the constant a distinct value, or reuse the existing '
      'constant.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a class or enum declaration has several constants holding the
/// same primitive value.
///
/// Two constants with the same value in one declaration are almost always a
/// copy-paste slip: one of them is dead, and callers picking between them are
/// choosing between synonyms.
///
/// Catches:
/// - `static const` fields whose initializer is an `int`, `double`, `String` or
///   `bool` literal, in classes, enums, mixins and extensions.
/// - enum constants whose argument list is a single primitive literal, such as
///   `low(1), high(1)`.
///
/// Deliberately not caught:
/// - Constants whose value is a computed constant expression (`1 + 1`), because
///   that needs constant evaluation rather than literal comparison. See
///   `doc/LIMITATIONS.md`.
/// - Instance fields, which hold state rather than named constants.
/// - Equal-looking literals of different types: `0` and `'0'` are distinct.
///
/// Options:
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid-duplicate-constant-values:
///         ignored-values: ['0', '1', '']
/// ```
/// Values are matched against the literal's source text.
class AvoidDuplicateConstantValues extends AligRule {
  /// Warns when constants in one declaration share a primitive value.
  AvoidDuplicateConstantValues(CustomLintConfigs configs)
      : ignoredValues =
            RuleOptions(configs, _meta.name).stringList('ignored-values'),
        super(_meta, configs);

  /// Literal source texts that may repeat without being reported.
  final List<String> ignoredValues;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void checkMembers(List<ClassMember> members) {
      final seen = <String>{};

      for (final member in members) {
        if (member is! FieldDeclaration || !member.isStatic) continue;
        if (!member.fields.isConst) continue;

        for (final variable in member.fields.variables) {
          final key = _primitiveKeyOf(variable.initializer);
          if (key == null) continue;

          if (!seen.add(key)) reporter.atNode(variable, code);
        }
      }
    }

    context.registry.addClassDeclaration((node) => checkMembers(node.members));
    context.registry.addMixinDeclaration((node) => checkMembers(node.members));
    context.registry
        .addExtensionDeclaration((node) => checkMembers(node.members));

    context.registry.addEnumDeclaration((node) {
      checkMembers(node.members);

      final seen = <String>{};
      for (final constant in node.constants) {
        final arguments = constant.arguments?.argumentList.arguments;
        if (arguments == null || arguments.length != 1) continue;

        final key = _primitiveKeyOf(arguments.single);
        if (key == null) continue;

        if (!seen.add(key)) reporter.atNode(constant, code);
      }
    });
  }

  /// A type-qualified key for [expression] when it is a primitive literal, or
  /// `null` when it is anything else.
  ///
  /// The type prefix keeps `0` and `'0'` apart.
  String? _primitiveKeyOf(Expression? expression) {
    final literal = expression;
    final key = switch (literal) {
      IntegerLiteral() => 'int:${literal.value}',
      DoubleLiteral() => 'double:${literal.value}',
      BooleanLiteral() => 'bool:${literal.value}',
      SimpleStringLiteral() => 'String:${literal.value}',
      _ => null,
    };
    if (key == null) return null;

    final text = switch (literal) {
      SimpleStringLiteral() => literal.value,
      _ => literal.toString(),
    };

    return ignoredValues.contains(text) ? null : key;
  }
}
