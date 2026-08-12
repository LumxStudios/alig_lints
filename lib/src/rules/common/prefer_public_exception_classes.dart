import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-public-exception-classes',
  category: 'common',
  problemMessage: 'This exception is private, so code outside this library cannot '
      'catch it by type.',
  correctionMessage: 'Make the class public.',
  tags: ['error-handing', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an exception or error class is private.
///
/// ```dart
/// class _HiddenException implements Exception { … }
///
/// void risky() => throw _HiddenException('bad');
/// ```
/// The throw crosses the library boundary; the name does not. A caller outside can only
/// write `catch (error)` and inspect the string, or catch everything — so a failure this
/// library went to the trouble of describing precisely becomes untyped at the only place
/// it matters. Private exceptions are usually an oversight: the class was written next to
/// the code that throws it, before anyone tried to handle it from outside.
///
/// Reported for a private class that implements `Exception` or extends `Error`, directly
/// or through its hierarchy.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// Making the class public is a rename, so every mention of it changes — and if the
/// library exports it, that is a deliberate addition to the public API rather than an
/// edit.
class PreferPublicExceptionClasses extends AligRule {
  /// Warns when an exception type cannot be named from outside.
  PreferPublicExceptionClasses(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!node.name.lexeme.startsWith('_')) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;
      if (!_isThrowable(element.thisType)) return;

      reporter.atToken(node.name, code);
    });
  }
}

/// Whether [type] is an `Exception` or an `Error`, at any depth.
bool _isThrowable(InterfaceType type) {
  for (final candidate in [type, ...type.allSupertypes]) {
    final name = candidate.element.name;
    if (name == 'Exception' || name == 'Error') return true;
  }

  return false;
}
