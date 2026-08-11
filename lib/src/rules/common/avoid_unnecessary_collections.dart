import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-collections',
  category: 'common',
  problemMessage: 'This builds a one-element collection only to take that '
      'element back out.',
  correctionMessage: 'Use the element directly.',
  tags: ['correctness', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Accessors that hand back the only element of a one-element collection.
const _singleElementAccessors = {'first', 'last', 'single'};

/// Warns when a one-element collection literal is immediately reduced to its
/// element.
///
/// `[value].first` allocates a list, reads it back and throws it away; `value`
/// says the same thing. So does spreading a one-element literal:
/// `[...[value], ...others]` is `[value, ...others]`.
///
/// Literals with more than one element are left alone — there the accessor is
/// choosing between them — as is a one-element literal that is the value being
/// produced, such as `List<int> singleton(int value) => [value];`.
class AvoidUnnecessaryCollections extends AligRule {
  /// Warns when a collection literal is reduced to its only element.
  AvoidUnnecessaryCollections(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      if (_soleElementOfAccess(node) == null) return;

      reporter.atNode(node, code);
    });

    context.registry.addSpreadElement((node) {
      if (_soleElementOfSpread(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseTheElement()];
}

/// The lone element behind `[x].first` and friends, or `null`.
Expression? _soleElementOfAccess(PropertyAccess node) {
  if (!_singleElementAccessors.contains(node.propertyName.name)) return null;

  return _soleElementOf(node.target);
}

/// The lone element behind `...[x]`, or `null`.
Expression? _soleElementOfSpread(SpreadElement node) =>
    _soleElementOf(node.expression);

/// The single element of [expression] when it is a one-element list or set
/// literal.
Expression? _soleElementOf(Expression? expression) {
  final node = expression?.unParenthesized;

  final elements = switch (node) {
    ListLiteral(:final elements) => elements,
    SetOrMapLiteral(:final elements) when node.isSet => elements,
    _ => null,
  };
  if (elements == null || elements.length != 1) return null;

  final only = elements.single;

  // A nested spread or `if` is not a plain element.
  return only is Expression ? only : null;
}

class _UseTheElement extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    void replace(AstNode node, Expression element) {
      final builder = reporter.createChangeBuilder(
        message: 'Use the element directly',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, element.toSource());
      });
    }

    context.registry.addPropertyAccess((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final element = _soleElementOfAccess(node);
      if (element != null) replace(node, element);
    });

    context.registry.addSpreadElement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final element = _soleElementOfSpread(node);
      if (element != null) replace(node, element);
    });
  }
}
