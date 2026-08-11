import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether the position [node] sits in already fixes its type to [element].
///
/// A dot shorthand resolves against the type the context expects, so a rule may
/// only suggest one where that type is readable straight off the code. The
/// positions recognised here are exactly those:
/// - an argument whose parameter has that type;
/// - a variable declared with an explicit type annotation;
/// - the right-hand side of an assignment to a target of that type;
/// - the other side of an `==` or `!=` against a value of that type;
/// - a constant pattern in a switch whose subject has that type.
///
/// Positions where the type comes from inference — `final value = Size.small;`,
/// a collection literal's element type — deliberately return `false`. Suggesting
/// a shorthand there would be guessing at a context the code does not state.
bool expectedTypeIs(Expression node, InterfaceElement element) {
  final parent = node.parent;

  // This has to come before the parameter check: `==` is a method, so an operand
  // reports a corresponding parameter of type `Object`, which would end the
  // search on the wrong answer.
  if (parent is BinaryExpression) {
    final operator = parent.operator.lexeme;
    if (operator != '==' && operator != '!=') return false;

    final other =
        parent.leftOperand == node ? parent.rightOperand : parent.leftOperand;

    return isTypeOf(other.staticType, element);
  }

  final expression = parent is NamedExpression ? parent : node;
  final parameter = expression.correspondingParameter;
  if (parameter != null) return isTypeOf(parameter.type, element);

  if (parent is VariableDeclaration) {
    final declaration = parent.parent;
    if (declaration is VariableDeclarationList) {
      final type = declaration.type?.type;
      if (type != null) return isTypeOf(type, element);
    }

    return false;
  }

  if (parent is AssignmentExpression && parent.rightHandSide == node) {
    return isTypeOf(parent.writeType, element);
  }

  if (parent is ConstantPattern) {
    return isTypeOf(switchSubjectTypeOf(parent), element);
  }

  return false;
}

/// The static type of the switch subject enclosing [node], if any.
DartType? switchSubjectTypeOf(AstNode node) {
  final expression = node.thisOrAncestorOfType<SwitchExpression>();
  if (expression != null) return expression.expression.staticType;

  return node.thisOrAncestorOfType<SwitchStatement>()?.expression.staticType;
}

/// Whether [type] is exactly the interface declared by [element].
bool isTypeOf(DartType? type, InterfaceElement element) =>
    type is InterfaceType && type.element == element;
