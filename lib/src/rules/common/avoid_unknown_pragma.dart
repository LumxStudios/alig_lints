import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unknown-pragma',
  category: 'common',
  problemMessage: 'No tool recognises this pragma, so it is silently ignored.',
  correctionMessage: 'Use one of the documented pragma values, or remove it.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// The pragma values the Dart toolchain recognises.
///
/// A closed list is what makes this rule possible and also its main limitation: a
/// pragma added to the toolchain after this was written will be reported until the
/// list is updated. That trade is recorded in `doc/LIMITATIONS.md`.
const _known = {
  'vm:always-consider-inlining',
  'vm:awaiter-link',
  'vm:deeply-immutable',
  'vm:entry-point',
  'vm:exact-result-type',
  'vm:external-name',
  'vm:invisible',
  'vm:isolate-unsendable',
  'vm:never-inline',
  'vm:non-nullable-result-type',
  'vm:notify-debugger-on-exception',
  'vm:prefer-inline',
  'vm:recognized',
  'vm:shared',
  'vm:testing:print-flow-graph',
  'vm:unsafe:no-interrupts',
  'dart2js:as:trust',
  'dart2js:index-bounds:trust',
  'dart2js:late:check',
  'dart2js:late:trust',
  'dart2js:load-priority',
  'dart2js:noInline',
  'dart2js:noThrows',
  'dart2js:noSideEffects',
  'dart2js:tryInline',
  'flutter:keep-to-string',
  'flutter:keep-to-string-in-subtypes',
  'wasm:entry-point',
  'wasm:export',
  'wasm:import',
  'wasm:prefer-inline',
  'wasm:weak-export',
};

/// Warns when `@pragma` is given a value no tool understands.
///
/// ```dart
/// @pragma('vm:prefer-inlining')   // the real one is 'vm:prefer-inline'
/// int typo() => 1;
/// ```
/// A pragma is a plain string, so a typo compiles and does nothing. The annotation
/// stays in the source looking like it has an effect — and where the pragma was
/// load-bearing, such as `vm:entry-point` on a callback the platform invokes, the
/// failure is a crash at run time in code that appears to be annotated correctly.
///
/// Only a string literal is checked. `@pragma(someConstant)` is not reported: the
/// value is not visible at the annotation, and following it would mean resolving
/// constants for a rule whose whole basis is a name.
///
/// No quick-fix is offered. The nearest known name is usually the right one, but
/// "usually" is not good enough for something whose whole purpose is to change how
/// the compiler treats the code beneath it.
class AvoidUnknownPragma extends AligRule {
  /// Warns when a pragma value is not one the toolchain knows.
  AvoidUnknownPragma(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAnnotation((node) {
      if (node.name.name != 'pragma') return;

      final first = node.arguments?.arguments.firstOrNull;
      if (first is! SimpleStringLiteral) return;
      if (_known.contains(first.value)) return;

      reporter.atNode(first, code);
    });
  }
}
