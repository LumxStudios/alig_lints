import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unsafe-collection-methods',
  category: 'common',
  problemMessage: '{0} throws when the collection has nothing to return.',
  correctionMessage: 'Guard the access, or use a form that yields null instead.',
  tags: ['correctness', 'maintainability', 'cwe', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Accessors that throw when the collection is empty.
const _unsafeAccessors = {'first', 'last', 'single'};

/// Methods that throw when nothing matches, unless given an `orElse`.
const _searchMethods = {'firstWhere', 'lastWhere', 'singleWhere'};

/// Methods that throw on an empty collection outright.
const _unsafeMethods = {'reduce', 'elementAt'};

/// Warns about collection accesses that throw when there is nothing to return.
///
/// `items.first` on an empty list, `items.firstWhere(...)` when nothing matches,
/// `items.reduce(...)` with no elements — each throws at runtime where a
/// null-returning form would let the caller decide.
///
/// A `firstWhere` with an `orElse` is total and is not reported, nor is an access
/// on a non-empty collection literal, which cannot be empty.
///
/// No quick-fix is offered: the null-returning forms — `firstOrNull` and its
/// relatives — live in `package:collection`, so applying one means adding a
/// dependency and an import. That is more than a fix should do on its own, and
/// the catalogue's own suggestion of a fix cannot be honoured without it.
class AvoidUnsafeCollectionMethods extends AligRule {
  /// Warns about collection accesses that can throw.
  AvoidUnsafeCollectionMethods(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      final name = node.propertyName.name;
      if (!_unsafeAccessors.contains(name)) return;
      if (!_isRiskyIterable(node.realTarget)) return;

      reporter.atNode(node.propertyName, code, arguments: [name]);
    });

    context.registry.addPrefixedIdentifier((node) {
      final name = node.identifier.name;
      if (!_unsafeAccessors.contains(name)) return;
      if (!_isRiskyIterable(node.prefix)) return;

      reporter.atNode(node.identifier, code, arguments: [name]);
    });

    context.registry.addMethodInvocation((node) {
      final name = node.methodName.name;
      final target = node.realTarget;
      if (target == null || !_isRiskyIterable(target)) return;

      if (_searchMethods.contains(name)) {
        if (_hasOrElse(node.argumentList)) return;

        reporter.atNode(node.methodName, code, arguments: [name]);

        return;
      }

      if (_unsafeMethods.contains(name)) {
        reporter.atNode(node.methodName, code, arguments: [name]);
      }
    });
  }
}

/// Whether [expression] is an iterable that might have nothing to return.
bool _isRiskyIterable(Expression? expression) {
  final node = expression?.unParenthesized;
  if (node == null) return false;

  // A literal with elements cannot be empty.
  final elements = switch (node) {
    ListLiteral(:final elements) => elements,
    SetOrMapLiteral(:final elements) when node.isSet => elements,
    _ => null,
  };
  if (elements != null && elements.isNotEmpty) return false;

  final type = node.staticType;
  if (type is! InterfaceType) return false;

  return type.isDartCoreIterable ||
      type.allSupertypes.any((supertype) => supertype.isDartCoreIterable);
}

bool _hasOrElse(ArgumentList arguments) => arguments.arguments.any(
      (argument) =>
          argument is NamedExpression && argument.name.label.name == 'orElse',
    );
