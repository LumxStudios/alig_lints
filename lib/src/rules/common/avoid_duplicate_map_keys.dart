import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-map-keys',
  category: 'common',
  problemMessage: 'This key already appears in the map, so the earlier entry is '
      'silently discarded.',
  correctionMessage: 'Remove one of the entries, or correct the key.',
  tags: ['correctness', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a map literal contains the same key twice.
///
/// In a map literal the later entry wins, so the earlier one is dead code and
/// the value a reader expects to find may not be there. Dart itself reports this
/// only for `const` maps; this rule covers ordinary ones.
///
/// The report sits on the later, winning entry — that is the key a reader is
/// looking at — while the quick-fix deletes the *earlier*, discarded entry, so
/// applying it cannot change what the map evaluates to.
///
/// Deliberately not caught: keys inside `if` or `for` elements, which are not
/// statically comparable, and keys whose expressions have side effects.
/// Equal-looking keys of different types stay distinct, so `0` and `'0'` are
/// two keys.
class AvoidDuplicateMapKeys extends AligRule {
  /// Warns when a map literal has duplicate keys.
  AvoidDuplicateMapKeys(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSetOrMapLiteral((node) {
      final seen = <String>{};

      for (final entry in node.elements.whereType<MapLiteralEntry>()) {
        final key = _keyOf(entry);
        if (key == null) continue;

        if (!seen.add(key)) reporter.atNode(entry, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveDiscardedEntry()];
}

/// A comparable key for [entry], or `null` when its key is not safe to compare.
String? _keyOf(MapLiteralEntry entry) {
  final key = entry.key;
  if (hasSideEffects(key)) return null;

  // The static type keeps equal-looking literals of different types apart.
  final type = key.staticType?.getDisplayString() ?? 'unknown';

  return '$type:${canonicalize(key)}';
}

class _RemoveDiscardedEntry extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addSetOrMapLiteral((node) {
      final entries = node.elements.whereType<MapLiteralEntry>().toList();
      final index = entries.indexWhere(
        (entry) => entry.sourceRange == diagnostic.sourceRange,
      );
      if (index < 0) return;

      final key = _keyOf(entries[index]);
      if (key == null) return;

      // The discarded entry is the closest earlier one with the same key.
      final discarded = entries
          .take(index)
          .where((entry) => _keyOf(entry) == key)
          .lastOrNull;
      if (discarded == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the earlier entry that this key discards',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(rangeRemovingListItem(discarded, resolver));
      });
    });
  }
}
