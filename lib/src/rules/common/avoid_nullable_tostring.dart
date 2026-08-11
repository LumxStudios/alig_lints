import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-nullable-tostring',
  category: 'common',
  problemMessage: 'This value can be null, and toString then returns the word '
      '"null" rather than failing.',
  correctionMessage: 'Supply a fallback with ?? , or use ?. so the result is '
      'nullable and has to be handled.',
  tags: ['correctness', 'cwe', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `toString()` is called on a value that can be null.
///
/// ```dart
/// void log(String? name) => print(name.toString());
/// ```
/// This compiles: `Null` has a `toString` of its own, so a nullable receiver is
/// allowed and returns `"null"`. That is the whole problem — the call cannot
/// fail, so a missing value becomes the four-letter string `null` in whatever
/// the text was for, and no error marks where it happened.
///
/// A receiver the type system has already ruled out is not reported, so
/// `(name ?? 'unknown').toString()`, `name!.toString()` and anything promoted by
/// an earlier check all pass.
///
/// `name?.toString()` is not reported either. The call never reaches a null, and
/// the `String?` it returns is something the type system keeps track of — which
/// is exactly what the unconditional call throws away.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not
/// reproduced: rewriting to `?.` changes the expression's type from `String` to
/// `String?`, which will not compile wherever a `String` was expected, and
/// choosing the fallback text instead is a decision about what the reader should
/// see. The deviation is recorded in `doc/LIMITATIONS.md`.
class AvoidNullableTostring extends AligRule {
  /// Warns when a `toString()` receiver can be null.
  AvoidNullableTostring(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'toString') return;
      if (node.argumentList.arguments.isNotEmpty) return;
      // With ?. the call is skipped rather than made on a null.
      if (node.operator?.type == TokenType.QUESTION_PERIOD) return;

      final target = node.realTarget;
      if (target == null || !_isNullable(target.staticType)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether a value of [type] can be null at this point.
bool _isNullable(DartType? type) {
  if (type == null) return false;
  if (type is DynamicType || type is InvalidType) return false;

  return type.isDartCoreNull ||
      type.nullabilitySuffix == NullabilitySuffix.question;
}
