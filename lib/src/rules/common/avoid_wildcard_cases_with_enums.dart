import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-wildcard-cases-with-enums',
  category: 'common',
  problemMessage: 'A catch-all case stops the compiler reporting this switch when '
      'a new enum value is added.',
  correctionMessage: 'List every enum value instead.',
  tags: ['correctness', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a switch over an enum has a catch-all case.
///
/// Listing every value makes the switch exhaustive, and the compiler then flags it
/// the day a value is added. A `_` case or a `default` silently absorbs the new
/// value instead, which is how enum handling drifts out of date.
///
/// Both forms are reported: `case _:` and `default:` differ in spelling but have
/// the same effect on exhaustiveness, and a switch *expression* only has the
/// wildcard form, so treating them differently would be inconsistent.
///
/// Nullable enums are included. `Status?` is exhausted by the values plus `null`,
/// so a wildcard defeats the check there too.
///
/// No quick-fix is offered: filling in the missing cases means writing a body for
/// each, which only the author can do.
class AvoidWildcardCasesWithEnums extends AligRule {
  /// Warns when an enum switch has a catch-all case.
  AvoidWildcardCasesWithEnums(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchStatement((node) {
      if (!_isEnum(node.expression.staticType)) return;

      for (final member in node.members) {
        final token = _catchAllTokenOf(member);
        if (token != null) reporter.atToken(token, code);
      }
    });

    context.registry.addSwitchExpression((node) {
      if (!_isEnum(node.expression.staticType)) return;

      for (final switchCase in node.cases) {
        final pattern = switchCase.guardedPattern.pattern;
        if (pattern is WildcardPattern) reporter.atNode(pattern, code);
      }
    });
  }
}

/// Whether [type] is an enum, with or without a `?`.
bool _isEnum(DartType? type) =>
    type is InterfaceType && type.element is EnumElement;

/// The token introducing a catch-all case, or `null` when [member] handles a
/// specific value.
Token? _catchAllTokenOf(SwitchMember member) => switch (member) {
      SwitchDefault() => member.keyword,
      SwitchPatternCase(:final guardedPattern) =>
        guardedPattern.pattern is WildcardPattern ? member.keyword : null,
      _ => null,
    };
