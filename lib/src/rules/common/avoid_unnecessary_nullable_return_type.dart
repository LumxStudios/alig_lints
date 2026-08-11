import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/control_flow_utils.dart';
import '../../common/null_checks.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-nullable-return-type',
  category: 'common',
  problemMessage: 'Every path here returns a value, so the ? promises a null '
      'that never comes back.',
  correctionMessage: 'Make the return type non-nullable.',
  tags: ['correctness', 'maintainability', 'nullability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a nullable return type never actually returns null.
///
/// ```dart
/// String? label(bool short) => short ? 'S' : 'long';
/// ```
/// The `?` makes every caller handle a case the function cannot produce. The
/// cost lands on them — a `??`, a `!`, or a null check at each call — for a null
/// that is not there.
///
/// A function is reported only when null is genuinely unreachable: every
/// `return` carries a non-nullable value, there is at least one, none is a bare
/// `return;`, and the body cannot end without returning. That last condition is
/// what keeps `if (found) return 'a';` with nothing after it out of the report —
/// falling off the end returns null.
///
/// `async` bodies are read through the `Future`, so `Future<String?>` is judged
/// by what the returns carry rather than by the future itself. Generators are
/// skipped: their returns do not produce the yielded values.
///
/// A returned value typed `dynamic` counts as possibly null, so it keeps a
/// function out of the report. `isDefinitelyNonNullable` in
/// `lib/src/common/null_checks.dart` explains why that differs from what the
/// rules reporting nullable values do.
///
/// Overriding methods are skipped — the supertype's signature decides the type,
/// and narrowing it here would not be honoured anyway.
///
/// The fix removes the `?` only where no subclass could contradict it: top-level
/// functions, static methods, and methods of `final` or `sealed` classes.
/// Narrowing an ordinary instance method's return type would break any override
/// elsewhere that still returns null, and that override is not visible from
/// here — so those are reported without a fix.
class AvoidUnnecessaryNullableReturnType extends AligRule {
  /// Warns when a nullable return type is never used to return null.
  AvoidUnnecessaryNullableReturnType(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      final body = node.functionExpression.body;
      final returnType = _nullablePartOf(node.returnType, body);
      if (returnType == null || !_neverReturnsNull(body, returnType)) return;

      reporter.atNode(returnType, code);
    });

    context.registry.addMethodDeclaration((node) {
      // The supertype's signature decides this one.
      if (node.declaredFragment?.element.metadata.hasOverride ?? true) return;

      final returnType = _nullablePartOf(node.returnType, node.body);
      if (returnType == null || !_neverReturnsNull(node.body, returnType)) {
        return;
      }

      reporter.atNode(returnType, code);
    });
  }

  @override
  List<Fix> getFixes() => [_MakeNonNullable()];
}

/// The written type annotation whose `?` this rule is about, or null when there
/// is none.
///
/// An `async` function declares `Future<String?>`: the `?` that matters sits on
/// the type argument, not on the future.
TypeAnnotation? _nullablePartOf(TypeAnnotation? declared, FunctionBody body) {
  if (declared == null) return null;

  if (body.isAsynchronous && declared is NamedType) {
    final arguments = declared.typeArguments?.arguments;
    if (arguments != null && arguments.length == 1) return arguments.single;
  }

  return declared;
}

/// Whether [body] is declared to return a nullable type yet cannot produce null.
bool _neverReturnsNull(FunctionBody body, TypeAnnotation returnType) {
  if (body is EmptyFunctionBody) return false;
  // A generator's returns do not carry the values it yields.
  if (body.isGenerator) return false;
  if (_questionTokenOf(returnType) == null) return false;

  if (body is ExpressionFunctionBody) {
    return isDefinitelyNonNullable(_returnedValueTypeOf(body.expression, body));
  }

  if (body is! BlockFunctionBody) return false;

  final visitor = _ReturnCollector();
  body.block.accept(visitor);
  // A bare `return;` in a nullable function hands back null.
  if (visitor.returned.isEmpty || visitor.hasBareReturn) return false;

  for (final value in visitor.returned) {
    if (!isDefinitelyNonNullable(_returnedValueTypeOf(value, body))) {
      return false;
    }
  }

  // Reaching the end of the body without returning also hands back null.
  final statements = body.block.statements;

  return statements.isNotEmpty && alwaysExits(statements.last);
}

/// The type a `return` in [body] actually contributes.
///
/// An `async` body may return either a value or a future of one, and it is the
/// value that reaches the caller either way.
DartType? _returnedValueTypeOf(Expression value, FunctionBody body) {
  final type = value.staticType;
  if (!body.isAsynchronous || type is! InterfaceType) return type;
  if (!type.isDartAsyncFuture) return type;

  return type.typeArguments.firstOrNull;
}

/// The `?` on [type], or null when it is not written nullable.
Token? _questionTokenOf(TypeAnnotation type) => switch (type) {
      NamedType(:final question) => question,
      GenericFunctionType(:final question) => question,
      _ => null,
    };

class _MakeNonNullable extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addNamedType((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final question = _questionTokenOf(node);
      if (question == null) return;
      if (!_isSafeToNarrow(node)) return;

      reporter
          .createChangeBuilder(
            message: 'Make the return type non-nullable',
            priority: 60,
          )
          .addDartFileEdit((builder) {
        builder.addDeletion(SourceRange(question.offset, question.length));
      });
    });
  }
}

/// Whether narrowing this return type can be done without invalidating an
/// override that is not visible from this file.
bool _isSafeToNarrow(TypeAnnotation returnType) {
  final method = returnType.thisOrAncestorOfType<MethodDeclaration>();
  if (method == null || method.isStatic) return true;

  final owner = method.parent;

  return owner is ClassDeclaration &&
      (owner.finalKeyword != null || owner.sealedKeyword != null);
}

/// Collects the returns of one body, ignoring those inside nested closures.
class _ReturnCollector extends RecursiveAstVisitor<void> {
  final returned = <Expression>[];
  bool hasBareReturn = false;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression == null) {
      hasBareReturn = true;
    } else {
      returned.add(expression);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
