import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-map-keys-contains',
  category: 'common',
  problemMessage: 'Searching the keys scans the whole map; containsKey looks the '
      'key up directly.',
  correctionMessage: 'Use containsKey.',
  tags: ['performance', 'collections'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a map is searched with `keys.contains` instead of `containsKey`.
///
/// `keys` hands back an ordinary iterable, so `contains` walks it; `containsKey`
/// uses the map's own lookup.
///
/// `values.contains` is not reported: `containsValue` scans the map just the
/// same, so there is nothing to gain.
class AvoidMapKeysContains extends AligRule {
  /// Warns when `keys.contains` replaces `containsKey`.
  AvoidMapKeysContains(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (_mapOfKeysContains(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseContainsKey()];
}

/// The map expression when [node] is `<map>.keys.contains(...)`, else `null`.
Expression? _mapOfKeysContains(MethodInvocation node) {
  if (node.methodName.name != 'contains') return null;
  if (node.argumentList.arguments.length != 1) return null;

  final target = node.realTarget?.unParenthesized;
  final (owner, property) = switch (target) {
    PrefixedIdentifier(:final prefix, :final identifier) => (
        prefix as Expression,
        identifier.name,
      ),
    PropertyAccess(:final target, :final propertyName) => (
        target,
        propertyName.name,
      ),
    _ => (null, null),
  };
  if (property != 'keys' || owner == null) return null;

  final type = owner.staticType;
  if (type is! InterfaceType) return null;
  if (!type.isDartCoreMap &&
      !type.allSupertypes.any((supertype) => supertype.isDartCoreMap)) {
    return null;
  }

  return owner;
}

class _UseContainsKey extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final map = _mapOfKeysContains(node);
      if (map == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use containsKey',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Replaces `<map>.keys.contains` with `<map>.containsKey`, leaving the
        // argument list where it is.
        fileBuilder.addSimpleReplacement(
          SourceRange(map.offset, node.methodName.end - map.offset),
          '${map.toSource()}.containsKey',
        );
      });
    });
  }
}
