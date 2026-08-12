import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-shadowing',
  category: 'common',
  problemMessage: 'This name already means something in an enclosing scope, so '
      'inside here it means something else.',
  correctionMessage: 'Rename one of them.',
  tags: ['readability', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a declaration takes a name an enclosing scope already uses.
///
/// ```dart
/// void nestedBlocks() {
///   final value = 1;
///   {
///     final value = 2;
///     print(value);   // the inner one
///   }
///   print(value);     // the outer one
/// }
/// ```
/// Two things share a name in one function, and which one a line means depends on
/// where the line is. Nothing fails, so the cost is paid by whoever reads it next —
/// and by whoever moves a line between the blocks, which changes what it does without
/// changing what it says.
///
/// **Locals and parameters only, and only against enclosing scopes inside the same
/// function.** A parameter that takes a field's name is how Dart is written —
/// `Holder(this.value)`, `int scaled(int value) => this.value * value` — so reporting
/// that would fire on the language's own idiom while saying nothing useful. The
/// narrowing is what makes the rule usable and is recorded in `doc/LIMITATIONS.md`.
///
/// Three shapes are covered, each against the names already in scope around it: a
/// nested block's variable, a closure's parameter, and a `for`-in variable.
///
/// One exclusion beyond that: a `BuildContext` parameter in a callback. Flutter's
/// builders pass one, and shadowing `build`'s `context` with it is the framework's own
/// convention — reporting it would fire across an entire app and pull against
/// `use-closest-build-context`, which wants the inner one used.
///
/// No quick-fix is offered: which of the two names should change is the decision, and
/// renaming either one means updating its uses.
class AvoidShadowing extends AligRule {
  /// Warns when an inner declaration reuses an outer name.
  AvoidShadowing(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionBody((body) {
      // Only the outermost body starts a walk; the nested ones are reached from it
      // with the enclosing names already in hand.
      final enclosing = body.thisOrAncestorMatching(
        (ancestor) => ancestor != body && ancestor is FunctionBody,
      );
      if (enclosing != null) return;

      _walk(body, _parameterNamesOf(body.parent), reporter, code);
    });
  }
}

/// Walks [node], reporting any declaration whose name is already in [visible].
///
/// Written per shape rather than as one generic child walk. A generic version missed
/// a block's own variables: `final value = 1;` declares its name two levels below the
/// statement, so by the time the walk reached the sibling block that shadows it, the
/// name had not been collected.
void _walk(
  AstNode node,
  Set<String> visible,
  DiagnosticReporter reporter,
  LintCode code,
) {
  if (node is Block) {
    var inScope = visible;
    for (final statement in node.statements) {
      _walk(statement, inScope, reporter, code);
      // A statement's declarations are visible to the statements after it.
      inScope = <String>{...inScope, ..._namesDeclaredByStatement(statement)};
    }

    return;
  }

  if (node is ForStatement) {
    final loopVariable = _forInVariableOf(node);
    if (loopVariable != null) {
      if (visible.contains(loopVariable.lexeme)) {
        reporter.atToken(loopVariable, code);
      }
      // Checked against the outer names, then added for the body.
      _walk(node.body, <String>{...visible, loopVariable.lexeme}, reporter, code);

      return;
    }
  }

  if (node is FunctionExpression) {
    // A function's parameters are checked against the names outside it, then added
    // for its body. Adding them first made every parameter shadow itself.
    final parameters =
        node.parameters?.parameters ?? const <FormalParameter>[];
    for (final parameter in parameters) {
      final parameterName = parameter.name;
      if (parameterName == null) continue;
      if (!visible.contains(parameterName.lexeme)) continue;
      if (_isFrameworkCallbackContext(parameter)) continue;

      reporter.atToken(parameterName, code);
    }
    _walk(
      node.body,
      <String>{...visible, ..._parameterNamesOf(node)},
      reporter,
      code,
    );

    return;
  }

  final name = _declaredNameOf(node);
  if (name != null && visible.contains(name.lexeme)) {
    reporter.atToken(name, code);
  }

  for (final child in _childrenOf(node)) {
    _walk(child, visible, reporter, code);
  }
}

/// Whether [parameter] is a `BuildContext` handed in by a framework callback.
///
/// Flutter's builder callbacks pass a `BuildContext`, and naming it `context` inside a
/// `build` method that already has one is the framework's own convention — every
/// `Builder`, `FutureBuilder` and `ListView.builder` does it. Reporting it would fire
/// across an entire app, and it would also work against `use-closest-build-context`,
/// which requires the inner one to be the one used.
bool _isFrameworkCallbackContext(FormalParameter parameter) =>
    isBuildContext(parameter.declaredFragment?.element.type);

/// The name [node] declares, when it is one of the declarations this rule looks at.
///
/// Parameters are not here: they are handled where the function is, so that they are
/// compared against the names outside it rather than against their own siblings.
Token? _declaredNameOf(AstNode node) => switch (node) {
      VariableDeclaration(:final name) => name,
      _ => null,
    };

/// The names [statement] declares in the block it belongs to.
Set<String> _namesDeclaredByStatement(Statement statement) =>
    switch (statement) {
      VariableDeclarationStatement(:final variables) => {
          for (final variable in variables.variables) variable.name.lexeme,
        },
      _ => const <String>{},
    };

/// The parameter names [node] brings into scope for the code inside it.
Set<String> _parameterNamesOf(AstNode? node) {
  final parameters = switch (node) {
    FunctionExpression(:final parameters) => parameters,
    MethodDeclaration(:final parameters) => parameters,
    ConstructorDeclaration(:final parameters) => parameters,
    _ => null,
  };

  return <String>{
    for (final parameter in parameters?.parameters ?? const <FormalParameter>[])
      ?parameter.name?.lexeme,
  };
}

/// The `for (final x in …)` variable of [node], or null for a classic `for`.
Token? _forInVariableOf(ForStatement node) {
  final parts = node.forLoopParts;

  return parts is ForEachPartsWithDeclaration ? parts.loopVariable.name : null;
}

/// The direct children of [node].
List<AstNode> _childrenOf(AstNode node) {
  final visitor = _ChildCollector(node);
  node.visitChildren(visitor);

  return visitor.children;
}

class _ChildCollector extends UnifyingAstVisitor<void> {
  _ChildCollector(this._parent);

  final AstNode _parent;
  final children = <AstNode>[];

  @override
  void visitNode(AstNode node) {
    if (node.parent == _parent) children.add(node);
  }
}
