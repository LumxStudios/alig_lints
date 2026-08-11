import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-type-casts',
  category: 'common',
  problemMessage: 'The collection already has these type arguments, so this '
      'cast produces a view of it and changes nothing.',
  correctionMessage: 'Remove the cast.',
  tags: ['correctness', 'unused-code', 'cwe', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `cast` is asked for the types a collection already has.
///
/// ```dart
/// void show(List<String> names) => print(names.cast<String>());
/// ```
/// `cast<String>` on a `List<String>` wraps the list in a view that checks every
/// element against a type they all have. It is a leftover: the list was
/// `List<Object>` when the call was written, and narrowing the declaration left
/// the cast behind, still allocating a wrapper on every use.
///
/// The type arguments must match *exactly*. `names.cast<Object>()` is not
/// reported even though it cannot fail, because removing it would change the
/// expression's static type from `List<String>` to `List<Object>` — which may be
/// the reason it is there.
///
/// **The `as` half of this rule is left to the analyzer.** Dart's own
/// `unnecessary_cast` — a warning that is on by default — already reports
/// `text as String` where `text` is a `String`. Measured, it does not report
/// `text as Object`, and rightly: that widening changes the static type, exactly
/// as with `cast`. The measurement is recorded in `doc/LIMITATIONS.md`.
///
/// The fix removes the call. It is safe because the arguments match: the
/// expression keeps the type it had, and the only thing lost is the wrapper.
class AvoidUnnecessaryTypeCasts extends AligRule {
  /// Warns when a `cast` restates the collection's own type arguments.
  AvoidUnnecessaryTypeCasts(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!_isRedundantCast(node)) return;

      reporter.atNode(node.methodName, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveCast()];
}

/// Whether [node] is a `cast` whose type arguments the target already has.
bool _isRedundantCast(MethodInvocation node) {
  if (node.methodName.name != 'cast') return false;
  if (node.argumentList.arguments.isNotEmpty) return false;

  final requested = node.typeArguments?.arguments;
  if (requested == null || requested.isEmpty) return false;

  final target = node.realTarget?.staticType;
  final current = _collectionArgumentsOf(target);
  if (current == null || current.length != requested.length) return false;

  for (var i = 0; i < current.length; i++) {
    if (current[i] != requested[i].type) return false;
  }

  return true;
}

/// The type arguments [type] carries as an iterable or a map, or null when it is
/// neither.
List<DartType>? _collectionArgumentsOf(DartType? type) {
  if (type is! InterfaceType) return null;

  for (final candidate in [type, ...type.allSupertypes]) {
    if (candidate.isDartCoreMap || candidate.isDartCoreIterable) {
      return candidate.typeArguments;
    }
  }

  return null;
}

class _RemoveCast extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.sourceRange != diagnostic.sourceRange) return;
      if (!_isRedundantCast(node)) return;

      final operator = node.operator;
      if (operator == null) return;

      reporter
          .createChangeBuilder(message: 'Remove the cast', priority: 60)
          .addDartFileEdit((builder) {
        // From the dot through the closing parenthesis.
        builder.addDeletion(
          SourceRange(operator.offset, node.end - operator.offset),
        );
      });
    });
  }
}
