import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// A private function or method together with every call to it in the file.
///
/// Shared by the rules that judge a parameter by what callers actually pass.
/// They reach opposite conclusions — one about parameters that are always null,
/// one about parameters that are never null — from the same reading of the call
/// sites, so that reading lives here rather than in each of them.
class PrivateCallable {
  /// Pairs a declaration with the calls that reach it.
  PrivateCallable(this.parameters, this.calls);

  /// The declaration's parameter list.
  final FormalParameterList parameters;

  /// The argument list of every call to this declaration in the file.
  final List<ArgumentList> calls;
}

/// Every private callable in [unit] whose calls can all be seen.
///
/// A declaration is included only when the file contains at least one call to
/// it — with none there is nothing to conclude — and when it is never mentioned
/// outside a call, since a tear-off is invoked through a variable this analysis
/// cannot follow.
///
/// Overriding methods are excluded: they can be entered through a supertype's
/// signature, so this file's calls are not the full set.
///
/// Privacy is library-scoped while this analysis is file-scoped, so a
/// declaration also used from a `part` or a sibling file of the same library is
/// judged on this file's calls alone. That narrowing is recorded in
/// `doc/LIMITATIONS.md`.
List<PrivateCallable> privateCallablesOf(CompilationUnit unit) {
  final declarations = _DeclarationCollector();
  final calls = _CallCollector();
  unit
    ..accept(declarations)
    ..accept(calls);

  final callables = <PrivateCallable>[];
  for (final declaration in declarations.declarations) {
    final element = declaration.element;
    if (element == null || calls.isTornOff(element)) continue;

    final argumentLists = calls.argumentListsFor(element);
    if (argumentLists.isEmpty) continue;

    callables.add(PrivateCallable(declaration.parameters, argumentLists));
  }

  return callables;
}

/// The expression bound to [parameter] in [argumentList], or null when the call
/// leaves the parameter out.
Expression? argumentFor(
  FormalParameterElement parameter,
  ArgumentList argumentList,
) {
  for (final argument in argumentList.arguments) {
    if (argument.correspondingParameter != parameter) continue;

    return argument is NamedExpression ? argument.expression : argument;
  }

  return null;
}

/// The default of [parameter], or null when it has none.
Expression? defaultValueOf(FormalParameter parameter) =>
    parameter is DefaultFormalParameter ? parameter.defaultValue : null;

class _Declaration {
  _Declaration(this.element, this.parameters);

  final Element? element;
  final FormalParameterList parameters;
}

class _DeclarationCollector extends RecursiveAstVisitor<void> {
  final declarations = <_Declaration>[];

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final parameters = node.functionExpression.parameters;
    if (parameters != null && _isPrivate(node.name.lexeme)) {
      declarations.add(
        _Declaration(node.declaredFragment?.element, parameters),
      );
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final parameters = node.parameters;
    final element = node.declaredFragment?.element;
    final overrides = element?.metadata.hasOverride ?? true;
    if (parameters != null && _isPrivate(node.name.lexeme) && !overrides) {
      declarations.add(_Declaration(element, parameters));
    }
    super.visitMethodDeclaration(node);
  }
}

bool _isPrivate(String name) => name.startsWith('_');

/// Collects, per callable element, the argument lists of its calls and whether
/// it is ever mentioned outside a call.
class _CallCollector extends RecursiveAstVisitor<void> {
  final _calls = <Element, List<ArgumentList>>{};
  final _tornOff = <Element>{};

  List<ArgumentList> argumentListsFor(Element element) =>
      _calls[element] ?? const [];

  bool isTornOff(Element element) => _tornOff.contains(element);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    if (element != null) {
      _calls.putIfAbsent(element, () => []).add(node.argumentList);
    }
    // Visit the arguments, but not the name — it is a call, not a tear-off.
    node.target?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // The declaration's own name is not a use of it.
    final parent = node.parent;
    if (parent is FunctionDeclaration && parent.name == node.token) return;
    if (parent is MethodDeclaration && parent.name == node.token) return;

    final element = node.element;
    if (element is ExecutableElement) _tornOff.add(element);
  }
}
