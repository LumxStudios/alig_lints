import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-collection-equality-checks',
  category: 'common',
  problemMessage: 'Collections compare by identity, so this asks whether the two '
      'are the same object rather than whether they hold the same values.',
  correctionMessage: 'Compare the contents, for example with a deep equality '
      'helper.',
  tags: ['correctness', 'cwe', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when two collections are compared with `==` or `!=`.
///
/// `List`, `Set`, `Map` and `Iterable` inherit `Object`'s identity equality, so
/// `first == second` is false for two collections holding identical values. The
/// check almost always meant to compare contents.
///
/// A type that declares its own `==` *outside the SDK* is left alone: there the
/// operator does mean what the code says, so an immutable collection with value
/// equality compares safely. The SDK qualifier matters — `List` itself declares
/// `operator ==` as a redeclaration of `Object`'s, without adding value equality,
/// so counting that would exempt every list.
///
/// No quick-fix is offered: which deep-equality helper to reach for depends on
/// the project.
class AvoidCollectionEqualityChecks extends AligRule {
  /// Warns when collections are compared by `==`.
  AvoidCollectionEqualityChecks(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      final operator = node.operator.lexeme;
      if (operator != '==' && operator != '!=') return;

      final left = node.leftOperand.staticType;
      final right = node.rightOperand.staticType;
      if (!_isIdentityComparedCollection(left)) return;
      if (!_isIdentityComparedCollection(right)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [type] is a collection that inherits identity equality.
bool _isIdentityComparedCollection(DartType? type) {
  if (type is! InterfaceType) return false;
  if (!_isCollection(type)) return false;

  return !_declaresEquality(type.element);
}

bool _isCollection(InterfaceType type) {
  if (type.isDartCoreIterable || type.isDartCoreMap) return true;

  return type.allSupertypes.any(
    (supertype) => supertype.isDartCoreIterable || supertype.isDartCoreMap,
  );
}

/// Whether [element] or a supertype declares `==` outside the SDK.
///
/// Declarations in `dart:` libraries do not count: `List` restates
/// `operator ==` without giving it value semantics, so treating that as a
/// value-equality type would silence the rule everywhere.
bool _declaresEquality(InterfaceElement element) {
  final candidates = [
    element,
    for (final supertype in element.allSupertypes) supertype.element,
  ];

  return candidates.any(
    (candidate) =>
        candidate.library.uri.scheme != 'dart' &&
        candidate.methods.any((method) => method.name == '=='),
  );
}
