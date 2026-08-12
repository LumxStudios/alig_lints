import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-shadowed-extension-methods',
  category: 'common',
  problemMessage: 'The extended type already has a member with this name, and its '
      'own always wins — so this one can never be called.',
  correctionMessage: 'Give the extension member a different name.',
  tags: ['correctness', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an extension member has a name the extended type already uses.
///
/// ```dart
/// extension OnStrings on String {
///   int get length => 0;   // String.length wins, always
/// }
/// ```
/// Extension members are only reachable when the type does not have that name
/// itself. Writing one that clashes produces no error and no warning: the member
/// simply never runs. Everything that reads `value.length` keeps calling `String`'s,
/// so the extension looks installed and does nothing — and a test of the extension
/// method, called directly, would pass.
///
/// Reported for a method, getter, setter or operator whose name is declared by the
/// extended type or anything it inherits from.
///
/// No quick-fix is offered: the repair is a new name, and every call the author
/// intended to reach has to be updated to it — which is exactly the set of calls
/// that currently go somewhere else.
class AvoidShadowedExtensionMethods extends AligRule {
  /// Warns when an extension member is unreachable behind the type's own.
  AvoidShadowedExtensionMethods(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExtensionDeclaration((node) {
      final extended = node.onClause?.extendedType.type;
      if (extended is! InterfaceType) return;

      final existing = _memberNamesOf(extended);

      for (final member in node.members) {
        final name = switch (member) {
          MethodDeclaration(:final name) => name,
          _ => null,
        };
        if (name == null || !existing.contains(name.lexeme)) continue;

        reporter.atToken(name, code);
      }
    });
  }
}

/// Every member name [type] declares or inherits.
Set<String> _memberNamesOf(InterfaceType type) {
  final names = <String>{};

  for (final candidate in [type, ...type.allSupertypes]) {
    final element = candidate.element;
    for (final method in element.methods) {
      names.addAll({?method.name});
    }
    for (final getter in element.getters) {
      names.addAll({?getter.name});
    }
    for (final setter in element.setters) {
      names.addAll({?setter.name});
    }
  }

  return names;
}
