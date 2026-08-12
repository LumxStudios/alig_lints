import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/field_assignment.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unassigned-fields',
  category: 'common',
  problemMessage: 'Nothing in this class ever assigns this field, so it keeps its '
      'initial value forever.',
  correctionMessage: 'Assign it, give it an initializer, or remove it.',
  tags: ['unused-code', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private field is never assigned a value.
///
/// ```dart
/// class Holder {
///   int? _never;
///
///   int get total => _never ?? 0;
/// }
/// ```
/// The field is read, so nothing calls it unused — but nothing ever writes it, so
/// every read gets `null`. The code around it looks like it handles a value that
/// arrives from somewhere, and no such value exists. This is what a half-finished
/// refactor leaves behind: the writer was removed and the reader stayed.
///
/// **Measured:** the analyzer's `unused_field` reports a field whose *value* is never
/// read. A field that is read but never written falls outside it, and nothing else
/// covers it; the measurement is in `doc/LIMITATIONS.md`.
///
/// Only private fields, because only for those can the whole set of writers be seen.
/// A public field can be assigned by anything that holds the object.
///
/// A field with an initializer, a field formal (`this._value`) and a field assigned
/// anywhere in the class — a constructor body, a method, a getter — all count as
/// assigned.
///
/// **`late` fields go to `avoid-unassigned-late-fields`.** The consequence differs
/// enough to be worth saying differently: an ordinary field that is never written
/// reads as `null` and the code limps on, while an unwritten `late` field throws
/// `LateInitializationError` the first time anything reads it. Two rules, so the
/// message can say which one happens.
///
/// No quick-fix is offered. Removing the field means removing every read of it, and
/// the alternative — finding what should have written it — is the repair the report
/// is asking for.
class AvoidUnassignedFields extends AligRule {
  /// Warns when nothing writes a private field.
  AvoidUnassignedFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final assigned = assignedElementsIn(node);

      for (final field in unassignableCandidatesOf(node, wantLate: false)) {
        final element = field.declaredFragment?.element;
        if (element == null) continue;
        if (assigned.contains(element)) continue;

        reporter.atToken(field.name, code);
      }
    });
  }
}
