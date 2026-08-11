import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-correct-json-casts',
  category: 'common',
  problemMessage: 'Decoded JSON is a Map<String, dynamic> or a List<dynamic> at '
      'run time, so casting straight to a narrower element type throws.',
  correctionMessage: 'Cast to the decoder\'s own type first, then convert the '
      'elements — for example `(value as List<dynamic>).cast<String>()`.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a cast on decoded JSON cannot succeed at run time.
///
/// ```dart
/// final root = jsonDecode(source) as Map<String, dynamic>;
/// final items = root['items'] as List<String>;
/// ```
/// `jsonDecode` builds `Map<String, dynamic>` and `List<dynamic>` — never
/// anything narrower, whatever the data looks like. Generic casts are checked on
/// the whole object, so `as List<String>` fails even when every element really is
/// a string. The static types allow it because the value is `dynamic`, so the
/// error waits until the line runs, usually in the one code path that parses a
/// real response.
///
/// Reported when the value being cast is `dynamic` **and** comes from a JSON
/// source — a `jsonDecode` call, or an index read on a map or list whose values
/// are `dynamic` — and the target type is a `List` or `Map` with a type argument
/// narrower than `dynamic` or `Object?`.
///
/// Casts to what the decoder actually produces are left alone, as are casts to a
/// plain `String`, `int` or `bool`: those are checks on a single value and they
/// work.
///
/// No quick-fix is offered. `(value as List<dynamic>).cast<String>()` still
/// throws on the first bad element, `List<String>.from(value)` copies, and
/// `whereType<String>()` silently drops what does not match — three different
/// answers to "what should happen if the data disagrees", which is the question
/// the broken cast was avoiding.
class PreferCorrectJsonCasts extends AligRule {
  /// Warns when decoded JSON is cast to a type it cannot have.
  PreferCorrectJsonCasts(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAsExpression((node) {
      if (node.expression.staticType is! DynamicType) return;
      if (!_isJsonSource(node.expression)) return;
      if (!_demandsNarrowElements(node.type.type)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [expression] is a value the JSON decoder produced.
bool _isJsonSource(Expression expression) {
  final node = expression.unParenthesized;

  if (node is MethodInvocation) {
    final name = node.methodName.name;

    return name == 'jsonDecode' || name == 'decode';
  }

  // Reading out of an already-decoded map or list.
  if (node is IndexExpression) {
    final target = node.realTarget.staticType;
    if (target is! InterfaceType) return false;
    if (!target.isDartCoreMap && !target.isDartCoreList) return false;

    return target.typeArguments.last is DynamicType;
  }

  return false;
}

/// Whether [type] is a `List` or `Map` asking for elements the decoder never
/// produces.
bool _demandsNarrowElements(DartType? type) {
  if (type is! InterfaceType) return false;
  if (!type.isDartCoreList && !type.isDartCoreMap) return false;

  // A map's key is always String in decoded JSON, so only the value matters;
  // for a list there is one argument and it is the element.
  final elementType = type.typeArguments.lastOrNull;

  return elementType != null && !_isWideEnough(elementType);
}

/// Whether the decoder's `dynamic` elements satisfy [type] as written.
bool _isWideEnough(DartType type) =>
    type is DynamicType || type.isDartCoreObject;
