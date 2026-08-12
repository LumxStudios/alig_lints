import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-inconsistent-digit-separators',
  category: 'common',
  problemMessage: 'These separators split the number into groups of different '
      'sizes, so the grouping misleads rather than helps.',
  correctionMessage: 'Group the digits evenly, from the right.',
  tags: ['readability', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when digit separators produce uneven groups.
///
/// ```dart
/// const uneven = 1_000_00;
/// ```
/// Separators exist so the size of a number can be read at a glance. `1_000_00`
/// invites the reader to see a million and it is a hundred thousand — the grouping
/// actively works against the value. This is nearly always a typo, and one that no
/// amount of rereading catches, because the eye trusts the groups.
///
/// The check is on the groups themselves: every group except the leading one must
/// have the same length. `12_345_678` is fine — a short leading group is how
/// grouping from the right works — while `12_34_5` is not.
///
/// Applies to any radix, so `0xFF_FF_FF` in pairs is fine and `0xFF_FFF_FF` is not.
/// A number with no separators is not this rule's business.
///
/// No quick-fix is offered. Regrouping into threes assumes that is what was meant,
/// and the more likely repair is a different number — `1_000_00` was probably
/// supposed to be `1_000_000`, which a fix must not guess at.
class AvoidInconsistentDigitSeparators extends AligRule {
  /// Warns when digit groups have inconsistent sizes.
  AvoidInconsistentDigitSeparators(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIntegerLiteral((node) {
      if (!_hasUnevenGroups(node.literal.lexeme)) return;

      reporter.atNode(node, code);
    });

    context.registry.addDoubleLiteral((node) {
      if (!_hasUnevenGroups(node.literal.lexeme)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [lexeme]'s separated groups disagree in length.
///
/// Only the groups after the leading one have to match each other: grouping runs
/// from the right, so the first group is legitimately short.
bool _hasUnevenGroups(String lexeme) {
  final digits = _digitsOf(lexeme);
  if (!digits.contains('_')) return false;

  final groups = digits.split('_');
  if (groups.length < 2) return false;
  // An empty group means two separators in a row, which no grouping intends.
  if (groups.any((group) => group.isEmpty)) return true;

  final expected = groups.last.length;

  return groups.skip(1).any((group) => group.length != expected);
}

/// The digits of [lexeme] without a radix prefix or an exponent.
String _digitsOf(String lexeme) {
  var digits = lexeme;
  if (digits.startsWith('0x') || digits.startsWith('0X')) {
    digits = digits.substring(2);
  }

  final exponent = digits.indexOf(RegExp('[eE]'));

  return exponent == -1 ? digits : digits.substring(0, exponent);
}
