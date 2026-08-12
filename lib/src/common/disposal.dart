import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether [type] declares a `dispose` method anywhere in its hierarchy.
///
/// `dispose` specifically, not "some teardown method": a `StreamSubscription` is
/// released with `cancel` and a `Sink` with `close`, and the analyzer's own
/// `cancel_subscriptions` and `close_sinks` already report those. Keying on
/// `dispose` gives this package's disposal rules a clean partition with them
/// rather than a second warning on the same field.
bool isDisposable(DartType? type) {
  if (type is! InterfaceType) return false;

  for (final candidate in [type, ...type.allSupertypes]) {
    for (final method in candidate.element.methods) {
      if (method.name == 'dispose') return true;
    }
  }

  return false;
}

/// The names of the things [body] calls `dispose` on.
///
/// Covers `controller.dispose()`, `controller?.dispose()` and a cascade
/// `controller..dispose()`, which are the three spellings a teardown method uses.
Set<String> disposedNamesIn(FunctionBody body) {
  final visitor = _DisposeTargetCollector();
  body.accept(visitor);

  return visitor.names;
}

class _DisposeTargetCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'dispose') {
      final name = _nameOf(node.realTarget);
      if (name != null) names.add(name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final receiver = _nameOf(node.target);
    for (final section in node.cascadeSections) {
      if (section is MethodInvocation &&
          section.methodName.name == 'dispose' &&
          receiver != null) {
        names.add(receiver);
      }
    }
    super.visitCascadeExpression(node);
  }
}

/// The identifier [expression] names, seeing through `this.`, or null.
String? _nameOf(Expression? expression) => switch (expression) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      PropertyAccess(target: ThisExpression(), :final propertyName) =>
        propertyName.name,
      _ => null,
    };
