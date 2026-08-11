import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-any-or-every',
  category: 'common',
  problemMessage: 'Filtering and then asking whether anything is left is what '
      'any() says directly.',
  correctionMessage: 'Use any(), negated if you are checking for none.',
  tags: ['readability', 'collections'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests `any()` in place of filtering a collection and testing emptiness.
///
/// `items.where(test).isNotEmpty` is `items.any(test)`, and the `isEmpty` form is
/// its negation. Both stop at the first match either way, so the rewrite costs
/// nothing.
///
/// `every()` is not suggested. Reaching it from this shape means negating the
/// predicate — `where((e) => !test(e)).isEmpty` — and rewriting someone's closure
/// inside out is not something a fix should do. See `doc/LIMITATIONS.md`.
class PreferAnyOrEvery extends AligRule {
  /// Suggests `any()` for filter-then-test-emptiness chains.
  PreferAnyOrEvery(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      if (_rewriteOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseAny()];
}

/// The source [node] should become, or `null` when this rule does not apply.
String? _rewriteOf(PropertyAccess node) {
  final property = node.propertyName.name;
  final negate = switch (property) {
    'isNotEmpty' => false,
    'isEmpty' => true,
    _ => null,
  };
  if (negate == null) return null;

  final filter = node.realTarget.unParenthesized;
  if (filter is! MethodInvocation) return null;
  if (filter.methodName.name != 'where') return null;

  final source = filter.realTarget;
  if (source == null || !_isIterable(source.staticType)) return null;

  final arguments = filter.argumentList.arguments;
  if (arguments.length != 1 || arguments.single is NamedExpression) return null;

  final call = '${source.toSource()}.any(${arguments.single.toSource()})';

  return negate ? '!$call' : call;
}

bool _isIterable(DartType? type) {
  if (type is! InterfaceType) return false;

  return type.isDartCoreIterable ||
      type.allSupertypes.any((supertype) => supertype.isDartCoreIterable);
}

class _UseAny extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPropertyAccess((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final rewrite = _rewriteOf(node);
      if (rewrite == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use any()',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, rewrite);
      });
    });
  }
}
