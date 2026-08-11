import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-wildcard-cases-with-sealed-classes',
  category: 'common',
  problemMessage: 'A catch-all case stops the compiler reporting this switch when '
      'a new subtype is added.',
  correctionMessage: 'Handle every subtype instead.',
  tags: ['correctness', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a switch over a sealed type has a catch-all case.
///
/// A sealed hierarchy can only be extended in its own library, which is what lets
/// the compiler check that a switch covers it. A `_` case or a `default` gives that
/// up: the day a subtype appears, the switch quietly routes it to the catch-all
/// instead of failing to compile.
///
/// Both `case _:` / `default:` in statements and `_ =>` in expressions are
/// reported, on the same reasoning as `avoid-wildcard-cases-with-enums`.
///
/// Ordinary classes are unaffected — they can be extended from anywhere, so a
/// switch over one can never be exhaustive and the wildcard is required.
///
/// No quick-fix is offered: writing a body per subtype is the author's work.
class AvoidWildcardCasesWithSealedClasses extends AligRule {
  /// Warns when a sealed-type switch has a catch-all case.
  AvoidWildcardCasesWithSealedClasses(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchStatement((node) {
      if (!_isSealed(node.expression.staticType)) return;

      for (final member in node.members) {
        final token = _catchAllTokenOf(member);
        if (token != null) reporter.atToken(token, code);
      }
    });

    context.registry.addSwitchExpression((node) {
      if (!_isSealed(node.expression.staticType)) return;

      for (final switchCase in node.cases) {
        final pattern = switchCase.guardedPattern.pattern;
        if (pattern is WildcardPattern) reporter.atNode(pattern, code);
      }
    });
  }
}

/// Whether [type] is a sealed class or mixin, with or without a `?`.
bool _isSealed(DartType? type) {
  if (type is! InterfaceType) return false;

  final element = type.element;

  return switch (element) {
    ClassElement(:final isSealed) => isSealed,
    MixinElement() => false,
    _ => false,
  };
}

/// The token introducing a catch-all case, or `null` when [member] handles a
/// specific value.
Token? _catchAllTokenOf(SwitchMember member) => switch (member) {
      SwitchDefault() => member.keyword,
      SwitchPatternCase(:final guardedPattern) =>
        guardedPattern.pattern is WildcardPattern ? member.keyword : null,
      _ => null,
    };
