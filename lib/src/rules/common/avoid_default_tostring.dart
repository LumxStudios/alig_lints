import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/stringification.dart';

const _meta = AligRuleMeta(
  name: 'avoid-default-tostring',
  category: 'common',
  problemMessage: 'This type does not implement toString, so the call yields '
      "\"Instance of '...'\" instead of anything about the value.",
  correctionMessage: 'Implement toString on the type, or print the fields you '
      'actually need.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `toString()` is called on a type that never implements it.
///
/// ```dart
/// class Plain {
///   final int value = 1;
/// }
///
/// void log(Plain plain) => print(plain.toString());
/// ```
/// The output is `Instance of 'Plain'` — the same text for every instance, so
/// the log line records that something happened and nothing about what. The
/// defect surfaces when someone reads the log, long after the call was written.
///
/// A type counts as implementing `toString` if it or anything in its hierarchy
/// declares one, so subclasses and mixins both satisfy the rule. Enums are never
/// reported: their implicit `toString` names the constant.
///
/// Three targets are deliberately left alone:
///
/// - `Object` and `dynamic`, where the runtime type — and therefore the output —
///   is unknown at the call;
/// - abstract, sealed and mixin types, whose calls dispatch to some subtype that
///   may well describe itself;
/// - `super.toString()`, which is how an override delegates to the default on
///   purpose.
///
/// No quick-fix is offered: writing a useful `toString` means choosing which
/// fields identify the value, and only the author knows that.
class AvoidDefaultTostring extends AligRule {
  /// Warns when a `toString()` target has no `toString` implementation.
  AvoidDefaultTostring(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'toString') return;
      if (node.argumentList.arguments.isNotEmpty) return;

      final target = node.realTarget;
      // Delegating to the default is what an override is supposed to do.
      if (target == null || target is SuperExpression) return;

      final type = target.staticType;
      if (type is! InterfaceType) return;
      if (_describesItself(type)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether a call on [type] can be expected to produce meaningful text.
bool _describesItself(InterfaceType type) {
  // Object and dynamic say nothing about what they hold at run time.
  if (type.isDartCoreObject) return true;

  final element = type.element;
  if (element is EnumElement) return true;
  // These are never the type of the receiver at run time; a subtype is.
  if (element is MixinElement) return true;
  if (element is ClassElement && (element.isAbstract || element.isSealed)) {
    return true;
  }

  return declaresToString(type);
}
