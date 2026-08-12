import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/field_assignment.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unassigned-late-fields',
  category: 'common',
  problemMessage: 'Nothing in this class assigns this late field, so the first '
      'read of it throws a LateInitializationError.',
  correctionMessage: 'Assign it before anything reads it, give it an initializer, '
      'or remove it.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private `late` field is never assigned.
///
/// ```dart
/// class Configured {
///   late final int _never;
///
///   int get total => _never;   // throws
/// }
/// ```
/// `late` is a promise to assign before reading. When nothing assigns at all, the
/// promise is broken in the worst way available: not a wrong value but a throw, from
/// the getter rather than from anything that looks responsible, and only on the path
/// that happens to read the field.
///
/// **The sibling `avoid-unassigned-fields` covers ordinary fields**, which read as
/// `null` and let the program limp on. The two are separate so that each can say what
/// actually happens; they never report the same field.
///
/// Only private fields, because only for those can every writer be seen. A field with
/// an initializer is assigned by definition.
///
/// No quick-fix is offered: the repair is the assignment, and where it belongs — a
/// constructor, an `initState`, a configure method — is the question the report is
/// asking.
class AvoidUnassignedLateFields extends AligRule {
  /// Warns when nothing assigns a private `late` field.
  AvoidUnassignedLateFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final assigned = assignedElementsIn(node);

      for (final field in unassignableCandidatesOf(node, wantLate: true)) {
        final element = field.declaredFragment?.element;
        if (element == null || assigned.contains(element)) continue;

        reporter.atToken(field.name, code);
      }
    });
  }
}
