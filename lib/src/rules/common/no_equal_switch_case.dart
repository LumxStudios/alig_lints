import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'no-equal-switch-case',
  category: 'common',
  problemMessage: 'Another case in this switch has the same body.',
  correctionMessage: 'Share one body by letting the cases fall through, or '
      'remove the redundant case.',
  tags: ['control-flow', 'correctness', 'maintainability', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when two cases of one switch statement have the same body.
///
/// Duplicated bodies are either a copy-paste slip or two cases that should share
/// one body by falling through.
///
/// Deliberately not reported:
/// - Cases with an empty body. That is exactly how fall-through is written, so
///   `case 4: case 5: ...` is correct code, not a duplicate.
/// - Bodies consisting only of `break;`. Listing values as explicit no-ops is a
///   common way to document that they were considered, and merging them would
///   lose that.
///
/// The `default` body takes part in the comparison, so a case that merely repeats
/// what `default` already does is reported.
///
/// No quick-fix is offered: merging the cases, deleting one, or correcting a body
/// that was meant to differ are all plausible intents, and they produce different
/// code.
class NoEqualSwitchCase extends AligRule {
  /// Warns when switch cases share a body.
  NoEqualSwitchCase(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchStatement((node) {
      final seen = <String>{};

      for (final member in node.members) {
        final key = _bodyKeyOf(member.statements);
        if (key == null) continue;

        if (!seen.add(key)) reporter.atToken(member.keyword, code);
      }
    });
  }
}

/// A comparable key for a case body, or `null` when the body should not be
/// compared at all.
String? _bodyKeyOf(List<Statement> statements) {
  if (statements.isEmpty) return null;
  if (statements.length == 1 && statements.single is BreakStatement) return null;

  return statements.map(canonicalize).join('\n');
}
