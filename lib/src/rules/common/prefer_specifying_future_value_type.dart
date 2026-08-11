import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/null_checks.dart';

const _meta = AligRuleMeta(
  name: 'prefer-specifying-future-value-type',
  category: 'common',
  problemMessage: 'This future is declared to carry a non-nullable value, and '
      'Future.value accepts a nullable one, so a null completes it as a value it '
      'cannot hold.',
  correctionMessage: 'Make the future\'s type argument nullable, or rule the '
      'null out before this call.',
  tags: ['correctness', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `Future.value` is handed a null that the future cannot carry.
///
/// ```dart
/// Future<String> load(String? maybe) => Future.value(maybe);
/// ```
/// This compiles. `Future.value`'s parameter is `FutureOr<T>?` — nullable
/// whatever `T` is — so a `String?` is accepted for a `Future<String>`. If the
/// value is null the future completes with null, and the `TypeError` surfaces at
/// the `await`, in whatever code was waiting, with nothing pointing back here.
///
/// **The no-argument case is left to the analyzer.** Measured, `Future.value()`
/// for a non-nullable `T` is already reported as `null_argument_to_non_null_type`
/// — a warning that is on by default. What it does not report is a nullable
/// *argument*, which is this rule's ground. The measurement is recorded in
/// `doc/LIMITATIONS.md`.
///
/// A future whose type argument is nullable is not reported, nor is
/// `Future<void>`: both can hold the null honestly.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not
/// reproduced. Widening the type argument to `String?` will not compile wherever
/// a `Future<String>` was expected, and adding `!` moves the throw earlier
/// without deciding what should happen when the value really is null — which is
/// the question this code is dodging.
class PreferSpecifyingFutureValueType extends AligRule {
  /// Warns when a nullable value is passed to a non-nullable future.
  PreferSpecifyingFutureValueType(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.name?.name != 'value') return;

      final created = node.staticType;
      if (created is! InterfaceType || !created.isDartAsyncFuture) return;

      // With no argument the analyzer already reports the null.
      final argument = node.argumentList.arguments.singleOrNull;
      if (argument == null) return;
      if (!isNullableType(argument.staticType)) return;

      final carried = created.typeArguments.singleOrNull;
      if (carried == null || !isDefinitelyNonNullable(carried)) return;

      reporter.atNode(node, code);
    });
  }
}
