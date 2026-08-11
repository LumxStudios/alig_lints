import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/type_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unrelated-type-casts',
  category: 'common',
  problemMessage: 'No value can have both of these types, so this cast throws '
      'whenever it runs.',
  correctionMessage: 'Cast to a type the value could actually have.',
  tags: ['correctness', 'cwe', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `as` or `cast` names a type the value cannot have.
///
/// ```dart
/// void show(int number) => print(number as String);
/// ```
/// This is not a cast that might fail — it is one that always does. The
/// `TypeError` arrives at run time, in whatever code path happens to reach the
/// line, rather than here where the mistake is visible.
///
/// `names.cast<int>()` on a `List<String>` is the same defect: the wrapper it
/// returns throws on the first element read, far from the call that built it.
///
/// **This only reports what can be proved**, on the same footing as
/// `avoid-unrelated-type-assertions`: the two share `areDisjointTypes` in
/// `lib/src/common/type_utils.dart`. One side must be a type nothing else can
/// implement — `int`, `double`, `String`, `bool`, `Null`, or an enum. Between two
/// ordinary classes a third could implement both, so `wrapper as Holder` stays
/// quiet.
///
/// This partitions with `avoid-unnecessary-type-casts`, which reports a `cast`
/// restating the arguments a collection already has. Equal types there,
/// impossible types here, and nothing in between.
///
/// No quick-fix is offered. The cast exists because someone expected the value
/// to have that type; the repair is to find out which type it really has, and
/// deleting the cast would silently change what the code does.
class AvoidUnrelatedTypeCasts extends AligRule {
  /// Warns when a cast can never succeed.
  AvoidUnrelatedTypeCasts(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAsExpression((node) {
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
      if (node.methodName.name != 'cast') return;
      if (node.argumentList.arguments.isNotEmpty) return;

      final typeSystem = typeSystemOf(node);
      final requested = node.typeArguments?.arguments.singleOrNull?.type;
      final element = iterableElementTypeOf(node.realTarget?.staticType);
      if (typeSystem == null || requested == null || element == null) return;
      if (!areDisjointTypes(element, requested, typeSystem)) return;

      reporter.atNode(node.methodName, code);
    });
  }
}
