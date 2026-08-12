import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-nested-records',
  category: 'common',
  problemMessage: 'A record inside a record has to be read positionally twice '
      'over, and neither level has a name to explain it.',
  correctionMessage: 'Give the inner record a name — a typedef, or a class.',
  tags: ['readability', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a record type contains another record type.
///
/// ```dart
/// (String, (int, bool)) build() => ('a', (1, true));
/// ```
/// A record's fields are identified by position, so reading this means counting
/// twice: `result.$2.$1`. Nothing in the type says what either level is for, and the
/// only place that could explain it — a name — is exactly what the nesting avoids.
/// A `typedef` for the inner record costs one line and makes the outer one legible.
///
/// Reported for a record type written inside another record type, at any depth.
/// A record inside a `List` or a `Map` is not reported: the collection names the
/// relationship, so only one level of positional reading is involved.
///
/// No quick-fix is offered: the repair is a name, and choosing it is the part that
/// carries the value.
class AvoidNestedRecords extends AligRule {
  /// Warns when a record type nests another.
  AvoidNestedRecords(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addRecordTypeAnnotation((node) {
      // Only the outermost record reports, so one nesting gives one diagnostic.
      if (node.thisOrAncestorMatching(
            (ancestor) =>
                ancestor != node && ancestor is RecordTypeAnnotation,
          ) !=
          null) {
        return;
      }

      if (!_containsRecord(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether any field of [node] is itself a record type.
bool _containsRecord(RecordTypeAnnotation node) {
  final fields = [
    ...node.positionalFields,
    ...?node.namedFields?.fields,
  ];

  for (final field in fields) {
    if (field.type is RecordTypeAnnotation) return true;
  }

  return false;
}
