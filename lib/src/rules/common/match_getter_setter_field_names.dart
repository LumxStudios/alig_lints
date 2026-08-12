import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'match-getter-setter-field-names',
  category: 'common',
  problemMessage: 'This accessor touches one field, and it is not the one its name '
      'refers to.',
  correctionMessage: 'Use the matching field, or rename the accessor.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an accessor is an alias for a field of a different name.
///
/// ```dart
/// int get width => _height;
/// ```
/// A copy-paste the type system cannot catch: both fields are `int`, so everything
/// compiles and `size.width` returns the height. The value is wrong everywhere it is
/// used, and the code reads correctly at every one of those places — the mistake is only
/// visible here.
///
/// **Only a pure alias is reported.** The getter's body has to be exactly a field
/// reference, and the setter's exactly an assignment of its parameter to a field.
/// Anything computed is left alone — `int get doubled => field * 2` touches a single
/// field too, and it is not claiming to be that field. An earlier version turned on the
/// *count* of fields touched and reported every one-field computed getter; the gate
/// caught it on two existing goldens.
///
/// **Extension types are skipped**, going to `avoid-renaming-representation-getters`
/// instead. On `extension type Meters(int value) { int get metres => value; }` both rules
/// see the same line, and that one's message names what is actually wrong.
///
/// The match ignores a leading underscore, so `width` pairs with `_width`.
///
/// No quick-fix is offered: the two repairs — use the other field, or rename the accessor
/// — have opposite effects on every caller, and which was meant is not visible from here.
class MatchGetterSetterFieldNames extends AligRule {
  /// Warns when an accessor aliases the wrong field.
  MatchGetterSetterFieldNames(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (!node.isGetter && !node.isSetter) return;
      // An extension type accessor is the sibling rule's business.
      if (node.parent is ExtensionTypeDeclaration) return;

      final aliased = node.isGetter
          ? _fieldReturnedBy(node.body)
          : _fieldAssignedBy(node.body, node.parameters);
      if (aliased == null) return;

      if (_matches(aliased, node.name.lexeme)) return;

      reporter.atToken(node.name, code);
    });
  }
}

/// The field a getter body hands straight back, or null when it does anything else.
String? _fieldReturnedBy(FunctionBody body) {
  final returned = switch (body) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block) => _singleReturnOf(block),
    _ => null,
  };

  return _fieldNameOf(returned);
}

/// The field a setter body assigns its parameter to, or null for anything else.
String? _fieldAssignedBy(FunctionBody body, FormalParameterList? parameters) {
  final assignment = switch (body) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block) => _singleExpressionOf(block),
    _ => null,
  };
  if (assignment is! AssignmentExpression) return null;
  if (assignment.operator.lexeme != '=') return null;

  // Only a straight `field = value`; anything else is doing work.
  final parameter = parameters?.parameters.singleOrNull?.declaredFragment?.element;
  final source = assignment.rightHandSide;
  if (source is! SimpleIdentifier || source.element != parameter) return null;

  return _fieldNameOf(assignment.leftHandSide, write: assignment);
}

Expression? _singleReturnOf(Block block) {
  final statement = block.statements.singleOrNull;

  return statement is ReturnStatement ? statement.expression : null;
}

Expression? _singleExpressionOf(Block block) {
  final statement = block.statements.singleOrNull;

  return statement is ExpressionStatement ? statement.expression : null;
}

/// The instance field [expression] refers to, or null when it is not one.
///
/// An assignment target carries no element on the identifier itself, so the [write] it
/// belongs to supplies the setter instead.
String? _fieldNameOf(Expression? expression, {AssignmentExpression? write}) {
  if (expression is! SimpleIdentifier) return null;

  final element = write?.writeElement ?? expression.element;
  final field = element is PropertyAccessorElement ? element.variable : element;

  return field is FieldElement && !field.isStatic ? field.name : null;
}

/// Whether [field] is the field [accessor] names, ignoring a leading underscore.
bool _matches(String field, String accessor) =>
    _withoutUnderscore(field) == _withoutUnderscore(accessor);

String _withoutUnderscore(String name) =>
    name.startsWith('_') ? name.substring(1) : name;
