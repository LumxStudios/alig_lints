import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';
import '../../common/rule_options.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-cascades',
  category: 'common',
  problemMessage: 'This cascade section repeats an earlier one in the same '
      'cascade, so it has no additional effect.',
  correctionMessage: 'Remove the duplicated section.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Methods whose repetition is meaningful by design, so repeating them is not a
/// mistake.
const _defaultIgnoredMethods = [
  'add',
  'addAll',
  'write',
  'writeln',
  'writeCharCode',
  'writeAll',
];

/// Warns when a cascade expression contains two structurally identical
/// sections.
///
/// Catches sections that are byte-for-byte equivalent after normalising
/// formatting, such as `..grow(1)..grow(1)` or `..width = 1 ... ..width = 1`.
///
/// Deliberately not caught:
/// - Assignments to the same target with *different* values
///   (`..width = 1..width = 3`). That is a dead write, but not a duplicate
///   section, and treating it as one risks flagging deliberate step-by-step
///   construction. See `doc/LIMITATIONS.md`.
/// - Accumulator methods, which repeat meaningfully. Configurable via
///   `ignored-methods`; defaults to [_defaultIgnoredMethods].
///
/// Options:
/// ```yaml
/// custom_lint:
///   rules:
///     - avoid-duplicate-cascades:
///         ignored-methods: ['add', 'push']
/// ```
class AvoidDuplicateCascades extends AligRule {
  /// Warns when a cascade expression has duplicate sections.
  AvoidDuplicateCascades(CustomLintConfigs configs)
      : ignoredMethods = RuleOptions(configs, _meta.name)
            .stringList('ignored-methods', orElse: _defaultIgnoredMethods),
        super(_meta, configs);

  /// Method names whose repetition inside a cascade is not reported.
  final List<String> ignoredMethods;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCascadeExpression((node) {
      final seen = <String>{};

      for (final section in node.cascadeSections) {
        if (_isIgnored(section)) continue;

        if (!seen.add(canonicalize(section))) {
          reporter.atNode(section, code);
        }
      }
    });
  }

  bool _isIgnored(Expression section) =>
      section is MethodInvocation &&
      ignoredMethods.contains(section.methodName.name);

  @override
  List<Fix> getFixes() => [_RemoveDuplicateCascade()];
}

class _RemoveDuplicateCascade extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addCascadeExpression((node) {
      final sections = node.cascadeSections;
      final index = sections.indexWhere(
        (section) => section.sourceRange == diagnostic.sourceRange,
      );
      if (index < 0) return;

      // Delete from the end of the preceding section so that the `;`
      // terminating the cascade, which shares a line with the last section,
      // survives.
      final previousEnd =
          index == 0 ? node.target.end : sections[index - 1].end;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the duplicated cascade section',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(
          rangeFollowing(previousEnd, sections[index]),
        );
      });
    });
  }
}
