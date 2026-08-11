import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-missing-enum-constant-in-map',
  category: 'common',
  problemMessage: 'This map is keyed by an enum but has no entry for {0}.',
  correctionMessage: 'Add the missing entries, or key the map by something '
      'else.',
  tags: ['correctness', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a map keyed by an enum leaves out some of its values.
///
/// A partial map reads like a total one: lookups for the missing values return
/// null, and adding an enum constant later leaves a hole nothing points at. The
/// message names the values that are absent.
///
/// Only maps whose contents are fully visible are checked. A computed key, a
/// spread or an `if` element means the entries are not known statically, so those
/// literals are left alone.
///
/// No quick-fix is offered: each missing entry needs a value only the author can
/// choose.
class AvoidMissingEnumConstantInMap extends AligRule {
  /// Warns when an enum-keyed map is missing values.
  AvoidMissingEnumConstantInMap(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSetOrMapLiteral((node) {
      final enumElement = _enumKeyOf(node);
      if (enumElement == null) return;

      final present = <String>{};
      for (final element in node.elements) {
        // Anything other than a plain entry hides what the map holds.
        if (element is! MapLiteralEntry) return;

        final name = _enumConstantNameOf(element.key, enumElement);
        if (name == null) return;

        present.add(name);
      }

      final missing = [
        for (final constant in _constantsOf(enumElement))
          if (!present.contains(constant)) constant,
      ];
      if (missing.isEmpty) return;

      reporter.atNode(node, code, arguments: [missing.join(', ')]);
    });
  }
}

/// The enum a map literal is keyed by, or `null`.
InterfaceElement? _enumKeyOf(SetOrMapLiteral node) {
  if (!node.isMap) return null;

  final type = node.staticType;
  if (type is! InterfaceType || !type.isDartCoreMap) return null;

  final key = type.typeArguments.firstOrNull;
  if (key is! InterfaceType) return null;

  return key.element is EnumElement ? key.element : null;
}

/// The name [expression] refers to, when it is a constant of [enumElement].
String? _enumConstantNameOf(Expression expression, InterfaceElement enumElement) {
  final node = expression.unParenthesized;

  final (owner, name) = switch (node) {
    PrefixedIdentifier(:final prefix, :final identifier) => (
        prefix.element,
        identifier.name,
      ),
    PropertyAccess(:final target, :final propertyName) => (
        target is Identifier ? target.element : null,
        propertyName.name,
      ),
    _ => (null, null),
  };

  return owner == enumElement ? name : null;
}

/// The names of [enumElement]'s constants.
List<String> _constantsOf(InterfaceElement enumElement) => [
      for (final field in enumElement.fields)
        if (field.isEnumConstant) field.name ?? '',
    ];
