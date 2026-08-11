import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-always-null-parameters',
  category: 'common',
  problemMessage: 'Every call passes null for this parameter, so it carries no '
      'information.',
  correctionMessage: 'Remove the parameter and use null directly in the body, '
      'or pass a real value at some call site.',
  tags: ['correctness', 'maintainability', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private function or method has a parameter that is null at
/// every call.
///
/// ```dart
/// String _format(String text, String? prefix) => '${prefix ?? ''}$text';
///
/// void run() {
///   print(_format('a', null));
///   print(_format('b', null));
/// }
/// ```
/// `prefix` looks like a knob but no caller ever turns it, so the branch that
/// reads it is dead weight. An optional parameter nobody ever supplies counts
/// too, as long as its default is `null`.
///
/// Only private declarations are considered. A public function can be called
/// from code this analysis never sees, so "every call passes null" would be a
/// claim about one file rather than about the program.
///
/// Even for a private name that claim needs the whole library in view, and
/// analysis here runs file by file. Declarations reachable from another part of
/// a multi-file library are therefore judged on this file's calls alone; the
/// narrowing is recorded in `doc/LIMITATIONS.md`.
///
/// Three shapes are deliberately left alone:
///
/// - declarations with no call in the file, where there is nothing to conclude
///   — an entirely uncalled private function is `avoid-unused-parameters`'
///   and the analyzer's business, not this rule's;
/// - declarations that are torn off (`final fn = _format;`), because the calls
///   then happen through a variable this rule cannot follow;
/// - parameters whose default is a non-null value, since omitting the argument
///   supplies that value rather than null.
///
/// No quick-fix is offered. Deleting the parameter leaves every use of it in
/// the body undefined, so the repair is to rewrite that body around a known
/// null — a judgement about what the code should do, not a mechanical edit.
class AvoidAlwaysNullParameters extends AligRule {
  /// Warns when no caller ever passes a value for a private parameter.
  AvoidAlwaysNullParameters(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      final calls = _CallCollector();
      unit.accept(calls);

      for (final declaration in _privateDeclarations(unit)) {
        final element = declaration.element;
        if (element == null) continue;

        final argumentLists = calls.argumentListsFor(element);
        if (argumentLists.isEmpty) continue;
        if (calls.isTornOff(element)) continue;

        for (final parameter in declaration.parameters.parameters) {
          if (_isAlwaysNull(parameter, argumentLists)) {
            reporter.atNode(parameter, code);
          }
        }
      }
    });
  }
}

/// Whether [parameter] receives null — explicitly or by default — at every one
/// of [argumentLists].
bool _isAlwaysNull(
  FormalParameter parameter,
  List<ArgumentList> argumentLists,
) {
  final element = parameter.declaredFragment?.element;
  if (element == null) return false;
  if (!_acceptsNull(element.type)) return false;

  // Omitting the argument only means "null" when the default says so.
  final defaultsToNull = _defaultValueOf(parameter) == null;

  for (final argumentList in argumentLists) {
    final argument = _argumentFor(element, argumentList);
    if (argument == null) {
      if (!defaultsToNull) return false;
      continue;
    }
    if (argument.unParenthesized is! NullLiteral) return false;
  }

  return true;
}

/// The expression bound to [parameter] in [argumentList], or null when the call
/// leaves the parameter out.
Expression? _argumentFor(
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
Expression? _defaultValueOf(FormalParameter parameter) =>
    parameter is DefaultFormalParameter ? parameter.defaultValue : null;

/// Whether a null argument would even be legal for [type].
bool _acceptsNull(DartType type) =>
    type is DynamicType || type.nullabilitySuffix == NullabilitySuffix.question;

/// Every private function and method declared in [unit], paired with its
/// element and parameter list.
List<_Declaration> _privateDeclarations(CompilationUnit unit) {
  final visitor = _DeclarationCollector();
  unit.accept(visitor);

  return visitor.declarations;
}

/// A private callable this rule can reason about.
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
    // An overriding method can be entered through a supertype's signature, so
    // this file's calls are not the full set.
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
