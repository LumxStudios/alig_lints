import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-nullable-interpolation',
  category: 'common',
  problemMessage: 'This value can be null, and the interpolation would then '
      'put the word "null" into the string.',
  correctionMessage: 'Supply a fallback with ?? , or check for null before '
      'building the string.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a nullable value is interpolated into a string.
///
/// ```dart
/// void log(String? name) => print('name: $name');
/// ```
/// When `name` is null the output is `name: null`. Nothing throws, so this
/// reaches users as a label reading "null" or a message with a hole in it, and
/// the null that caused it is long gone by then.
///
/// A value the type system already knows is non-null is not reported, so
/// `${name ?? 'unknown'}` and `${name!}` both pass — as does anything promoted
/// by an earlier null check.
///
/// Values typed `dynamic` are left alone. Every one of them can hold null, so
/// reporting them would say nothing about this string in particular;
/// `avoid-dynamic` reports the annotation that created the situation.
///
/// No quick-fix is offered: what should appear instead of "null" is a decision
/// about the text — an empty string, a dash, `unknown`, or omitting the whole
/// sentence — and only the author knows which the reader needs.
class AvoidNullableInterpolation extends AligRule {
  /// Warns when an interpolated value can be null.
  AvoidNullableInterpolation(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInterpolationExpression((node) {
      if (!_isNullable(node.expression.staticType)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether a value of [type] can be null at this point.
bool _isNullable(DartType? type) {
  if (type == null) return false;
  // Every dynamic can be null, which makes saying so here uninformative.
  if (type is DynamicType || type is InvalidType) return false;
  if (type is VoidType) return false;

  return type.isDartCoreNull ||
      type.nullabilitySuffix == NullabilitySuffix.question;
}
