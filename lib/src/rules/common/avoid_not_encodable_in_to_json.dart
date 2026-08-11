import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-not-encodable-in-to-json',
  category: 'common',
  problemMessage: 'jsonEncode cannot convert this value, and has no toJson to '
      'fall back to, so encoding the result throws.',
  correctionMessage: 'Convert it here — a String, a number, a bool, a List or a '
      'Map — or give its type a toJson method.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `toJson` method puts a value into the map that `jsonEncode`
/// cannot convert.
///
/// ```dart
/// Map<String, Object?> toJson() => {
///       'joined': joined,   // a DateTime
///       'status': status,   // an enum constant
///     };
/// ```
/// `jsonEncode` handles numbers, strings, bools, null, lists and string-keyed
/// maps; for anything else it calls `toJson()` on the object and throws
/// `JsonUnsupportedObjectError` when there is none. A `DateTime` field and an
/// enum constant both land in that gap. Because the map's value type is usually
/// `Object?`, nothing complains until the encode runs — typically in the request
/// that was supposed to send the data.
///
/// A type counts as encodable when it declares `toJson` anywhere in its
/// hierarchy, which is the same fallback the encoder uses, so nesting your own
/// models is not reported. Lists and maps are checked through to their elements.
///
/// Values typed `Object`, `dynamic` or a type parameter are left alone: what
/// they hold is not known here, and reporting them would fire on every
/// pass-through map.
///
/// No quick-fix is offered. `joined.toIso8601String()`, `joined.toString()` and
/// `joined.millisecondsSinceEpoch` are all reasonable, and they produce
/// different data — the receiver's format decides, not the compiler.
class AvoidNotEncodableInToJson extends AligRule {
  /// Warns when a `toJson` result contains something the encoder cannot take.
  AvoidNotEncodableInToJson(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'toJson') return;
      if (node.parameters?.parameters.isNotEmpty ?? false) return;

      for (final returned in _returnedExpressionsOf(node)) {
        for (final value in _encodedValuesOf(returned)) {
          if (_isEncodable(value.staticType, 0)) continue;

          reporter.atNode(value, code);
        }
      }
    });
  }
}

/// Every expression [node] hands back, whether from `=>` or from a `return`.
List<Expression> _returnedExpressionsOf(MethodDeclaration node) {
  final body = node.body;
  if (body is ExpressionFunctionBody) return [body.expression];

  final visitor = _ReturnCollector();
  body.accept(visitor);

  return visitor.returned;
}

/// The values inside [returned] that the encoder will have to convert — the
/// entries of a map literal, or the whole expression when it is not one.
List<Expression> _encodedValuesOf(Expression returned) {
  if (returned is! SetOrMapLiteral) return [returned];

  return [
    for (final element in returned.elements)
      if (element is MapLiteralEntry) element.value,
  ];
}

/// Whether `jsonEncode` can convert a value of [type].
///
/// [depth] bounds the walk through nested collections; a type nested deeper than
/// this is treated as encodable rather than reported on a guess.
bool _isEncodable(DartType? type, int depth) {
  if (type == null || depth > 4) return true;
  // Nothing is known about what these hold at the point of the call.
  if (type is DynamicType || type is InvalidType) return true;
  if (type is! InterfaceType) return true;
  if (type.isDartCoreObject) return true;

  if (type.isDartCoreNum ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreString ||
      type.isDartCoreBool ||
      type.isDartCoreNull) {
    return true;
  }

  if (type.isDartCoreList) {
    return _isEncodable(type.typeArguments.firstOrNull, depth + 1);
  }

  if (type.isDartCoreMap) {
    final key = type.typeArguments.firstOrNull;
    // Only string keys survive encoding.
    if (key is! InterfaceType || !key.isDartCoreString) return false;

    return _isEncodable(type.typeArguments.elementAtOrNull(1), depth + 1);
  }

  // The encoder's own fallback: call toJson on whatever it was handed.
  return _declaresToJson(type);
}

/// Whether [type] or anything it inherits from declares `toJson`.
bool _declaresToJson(InterfaceType type) {
  if (_hasToJsonMethod(type.element)) return true;
  for (final supertype in type.allSupertypes) {
    if (_hasToJsonMethod(supertype.element)) return true;
  }

  return false;
}

bool _hasToJsonMethod(InterfaceElement element) {
  for (final method in element.methods) {
    if (method.name == 'toJson') return true;
  }

  return false;
}

class _ReturnCollector extends RecursiveAstVisitor<void> {
  final returned = <Expression>[];

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression != null) returned.add(expression);
  }

  // A nested closure returns from itself, not from the toJson method.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
