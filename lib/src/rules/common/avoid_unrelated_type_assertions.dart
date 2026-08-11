import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/type_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unrelated-type-assertions',
  category: 'common',
  problemMessage: 'No value can have both of these types, so the answer is '
      'settled before the check runs.',
  correctionMessage: 'Test for a type the value could actually have.',
  tags: ['correctness', 'cwe', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `is` or `whereType` names a type the value cannot have.
///
/// ```dart
/// void check(int number) {
///   if (number is String) print('never runs');
/// }
/// ```
/// The branch is dead, and dead in a way that reads as live: someone wrote a
/// check, so someone believed the case was possible. It usually means the value
/// changed type — a field that used to be `Object`, an argument that used to
/// come from JSON — and the check was left behind guarding nothing.
///
/// `names.whereType<int>()` on an `Iterable<String>` is the same defect and is
/// reported too: the result is always empty.
///
/// **This only reports what can be proved.** Two types being unrelated is not
/// enough — a third class can implement both, so `wrapper is Holder` between two
/// ordinary classes stays quiet. One side must be a type nothing else can
/// implement: `int`, `double`, `String`, `bool`, `Null`, or an enum, whose set
/// of instances is fixed at its declaration.
///
/// That is narrow, and it is the reason Dart's own `unnecessary_type_check`
/// stops where it does. The two partition cleanly: it reports checks settled by
/// a subtype relation, this one reports checks settled by the absence of any
/// possible value. The measurement is in `doc/LIMITATIONS.md`.
///
/// No quick-fix is offered. The check is there because someone expected the type
/// to be possible, so the repair is to work out which type they meant — deleting
/// the branch would throw that question away.
class AvoidUnrelatedTypeAssertions extends AligRule {
  /// Warns when a type test can never succeed.
  AvoidUnrelatedTypeAssertions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIsExpression((node) {
      final typeSystem = typeSystemOf(node);
      if (typeSystem == null) return;
      if (!areDisjointTypes(
        node.expression.staticType,
        node.type.type,
        typeSystem,
      )) {
        return;
      }

      reporter.atNode(node, code);
    });

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'whereType') return;

      final typeSystem = typeSystemOf(node);
      final kept = node.typeArguments?.arguments.singleOrNull?.type;
      final element = iterableElementTypeOf(node.realTarget?.staticType);
      if (typeSystem == null || kept == null || element == null) return;
      if (!areDisjointTypes(element, kept, typeSystem)) return;

      reporter.atNode(node.methodName, code);
    });
  }
}
