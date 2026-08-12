import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-missed-calls',
  category: 'common',
  problemMessage: 'This names the method without calling it, so what arrives is '
      'the function itself rather than its result.',
  correctionMessage: 'Add () to call it.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a method is named where its result was meant.
///
/// ```dart
/// void show(User user) => print(user.name);
/// ```
/// The output is `Closure: () => String`. Nothing fails, because `print` takes
/// `Object?` and a function is an object — so the missing `()` survives review,
/// the tests, and ends up in a log or a user-visible string.
///
/// Reported where a **tear-off** — a method named without calling it — lands
/// somewhere that wants a plain value: an argument whose parameter is `Object`,
/// `Object?` or `dynamic`, or a string interpolation.
///
/// A tear-off handed to something that wants a callback is not reported; that is
/// what tear-offs are for. Neither is a variable that merely holds a function:
/// only a method or function named directly counts, which is what makes the
/// missing `()` legible as a mistake rather than a choice.
///
/// The fix appends `()`, and only when the method needs no arguments. A method
/// with a required parameter is reported without a fix — the call cannot be
/// completed without deciding what to pass.
class AvoidMissedCalls extends AligRule {
  /// Warns when a tear-off appears where a value is expected.
  AvoidMissedCalls(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInterpolationExpression((node) {
      if (!_isTearOff(node.expression)) return;

      reporter.atNode(node.expression, code);
    });

    context.registry.addArgumentList((node) {
      for (final argument in node.arguments) {
        if (!_isTearOff(argument)) continue;
        if (!_wantsAPlainValue(argument.correspondingParameter?.type)) continue;

        reporter.atNode(argument, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AddCall()];
}

/// Whether [expression] names a method or function without calling it.
bool _isTearOff(Expression expression) {
  if (expression.staticType is! FunctionType) return false;

  final element = switch (expression) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(identifier: SimpleIdentifier(:final element)) => element,
    PropertyAccess(propertyName: SimpleIdentifier(:final element)) => element,
    _ => null,
  };

  // A variable holding a function is a value someone chose to pass; only a
  // method or function named directly reads as a forgotten call.
  return element is MethodElement || element is TopLevelFunctionElement;
}

/// Whether [type] is a parameter type that would take anything, so a function
/// arriving there says nothing about intent.
bool _wantsAPlainValue(DartType? type) =>
    type is DynamicType || (type != null && type.isDartCoreObject);

class _AddCall extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final type = node.staticType;
      // Only a call that needs no arguments can be completed mechanically.
      if (type is! FunctionType) return;
      if (type.formalParameters.any((parameter) => parameter.isRequired)) {
        return;
      }

      reporter
          .createChangeBuilder(message: 'Add ()', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.end, '()');
      });
    });
  }
}
