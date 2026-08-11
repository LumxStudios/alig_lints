import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-shorthands-with-enums',
  category: 'common',
  problemMessage: 'The expected type already names this enum, so the shorthand '
      'says the same thing.',
  correctionMessage: 'Drop the enum name and keep the dot.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests the dot shorthand where an enum value's type is already known.
///
/// `Job(status: Status.active)` repeats `Status` next to a parameter already
/// declared as one; `status: .active` reads the same.
///
/// Reported only where the expected type can be read straight off the code, so
/// the suggestion is never a guess:
/// - an argument whose parameter is of the enum type;
/// - a variable declared with an explicit enum type;
/// - an assignment to a target of the enum type;
/// - the other side of an `==` or `!=` against the enum;
/// - a constant pattern in a switch whose subject is the enum.
///
/// `final value = Status.active;` is left alone — there is no declared type for a
/// shorthand to resolve against.
class PreferShorthandsWithEnums extends AligRule {
  /// Suggests dot shorthands for enum values.
  PreferShorthandsWithEnums(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final range = _redundantEnumNameRangeOf(node);
      if (range == null) return;

      reporter.atOffset(
        offset: range.offset,
        length: range.length,
        diagnosticCode: code,
      );
    });
  }

  @override
  List<Fix> getFixes() => [_UseShorthand()];
}

/// The range of the enum name in [node] when the expected type already fixes it.
SourceRange? _redundantEnumNameRangeOf(PrefixedIdentifier node) {
  final enumElement = _enumElementOf(node);
  if (enumElement == null) return null;
  if (!_expectedTypeIs(node, enumElement)) return null;

  return SourceRange(node.prefix.offset, node.prefix.length);
}

/// The enum [node] names, when it is an `Enum.value` reference.
InterfaceElement? _enumElementOf(PrefixedIdentifier node) {
  final prefixElement = node.prefix.element;
  if (prefixElement is! EnumElement) return null;

  // `Status.active.name` reaches past the value, so the prefix here is not the
  // whole reference.
  final value = node.identifier.element;
  if (value is! PropertyAccessorElement && value is! FieldElement) return null;

  return prefixElement;
}

/// Whether the position [node] sits in already expects [enumElement].
bool _expectedTypeIs(Expression node, InterfaceElement enumElement) {
  final parent = node.parent;

  // `status == Status.active`. This has to come before the parameter check:
  // `==` is a method, so an operand reports a corresponding parameter of type
  // Object, which would end the search on the wrong answer.
  if (parent is BinaryExpression) {
    final operator = parent.operator.lexeme;
    if (operator != '==' && operator != '!=') return false;

    final other =
        parent.leftOperand == node ? parent.rightOperand : parent.leftOperand;

    return _isThisEnum(other.staticType, enumElement);
  }

  // `Job(status: Status.active)` and positional arguments alike.
  final expression = parent is NamedExpression ? parent : node;
  final parameter = expression.correspondingParameter;
  if (parameter != null) return _isThisEnum(parameter.type, enumElement);

  // `Status current = Status.paused;`
  if (parent is VariableDeclaration) {
    final declaration = parent.parent;
    if (declaration is VariableDeclarationList) {
      final type = declaration.type?.type;
      if (type != null) return _isThisEnum(type, enumElement);
    }

    return false;
  }

  // `current = Status.paused;`
  if (parent is AssignmentExpression && parent.rightHandSide == node) {
    return _isThisEnum(parent.writeType, enumElement);
  }

  // `case Status.active:` and `Status.active => ...`
  if (parent is ConstantPattern) {
    return _isThisEnum(_switchSubjectTypeOf(parent), enumElement);
  }

  return false;
}

/// The static type of the switch subject enclosing [node], if any.
DartType? _switchSubjectTypeOf(AstNode node) {
  final expression = node.thisOrAncestorOfType<SwitchExpression>();
  if (expression != null) return expression.expression.staticType;

  return node.thisOrAncestorOfType<SwitchStatement>()?.expression.staticType;
}

bool _isThisEnum(DartType? type, InterfaceElement enumElement) =>
    type is InterfaceType && type.element == enumElement;

class _UseShorthand extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final range = _redundantEnumNameRangeOf(node);
      if (range == null || range.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use the shorthand',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(range);
      });
    });
  }
}
