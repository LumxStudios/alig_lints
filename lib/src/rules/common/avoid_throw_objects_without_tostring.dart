import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/stringification.dart';

const _meta = AligRuleMeta(
  name: 'avoid-throw-objects-without-tostring',
  category: 'common',
  problemMessage: 'This type does not implement toString, so whatever reports '
      "the error will show \"Instance of '...'\" and nothing about what failed.",
  correctionMessage: 'Implement toString on the thrown type, or throw one of '
      'the built-in errors that carries a message.',
  tags: ['correctness', 'cwe', 'error-handing'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when the object being thrown cannot describe itself.
///
/// ```dart
/// class Plain implements Exception {}
///
/// void fail() => throw Plain();
/// ```
/// Whatever catches this — a crash reporter, a log, the framework's own error
/// handler — will call `toString` on it and get `Instance of 'Plain'`. The one
/// moment the program had something to say about the failure is the moment it
/// says nothing, and the report that reaches you cannot be told apart from any
/// other `Plain`.
///
/// A type counts as describing itself if it or anything in its hierarchy
/// declares `toString`, so the built-in errors and your own exceptions with a
/// message both pass.
///
/// Abstract and sealed types are not reported: what is actually thrown is some
/// subtype, which may well describe itself. Neither is a value typed `Object` —
/// a rethrown `catch (e)` is the usual case, and what it holds is unknown here.
///
/// The check for a declared `toString` is shared with `avoid-default-tostring`
/// through `lib/src/common/stringification.dart`.
///
/// No quick-fix is offered: a useful `toString` has to say what went wrong, and
/// only the author knows that.
class AvoidThrowObjectsWithoutTostring extends AligRule {
  /// Warns when a thrown object has no `toString` implementation.
  AvoidThrowObjectsWithoutTostring(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addThrowExpression((node) {
      final type = node.expression.staticType;
      if (type is! InterfaceType) return;
      if (_canDescribeItself(type)) return;

      reporter.atNode(node.expression, code);
    });
  }
}

/// Whether a report of this thrown value will carry any information.
bool _canDescribeItself(InterfaceType type) {
  // A caught `Object` could be anything at run time, including something that
  // describes itself perfectly well.
  if (type.isDartCoreObject) return true;

  final element = type.element;
  // These are never what is actually thrown; a subtype is.
  if (element is ClassElement && (element.isAbstract || element.isSealed)) {
    return true;
  }
  if (element is MixinElement) return true;

  return declaresToString(type);
}
