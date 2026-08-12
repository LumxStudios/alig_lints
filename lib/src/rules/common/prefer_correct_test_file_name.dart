import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-correct-test-file-name',
  category: 'common',
  problemMessage: 'This file has a main under test/ but its name does not end in '
      '_test.dart, so the test runner will not run it.',
  correctionMessage: 'Rename the file to end with _test.dart.',
  tags: ['tests', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a file under `test/` has a `main` but the wrong name.
///
/// ```
/// test/parsing.dart      // has a main, never runs
/// test/parsing_test.dart // runs
/// ```
/// `dart test` collects files matching `*_test.dart`. A file that misses the suffix is
/// simply not collected: the suite passes, the count looks plausible, and the tests in
/// that file have never run. It is the worst kind of test failure, because it looks
/// like success — and it usually happens the moment a file is created or renamed.
///
/// Reported only for a file under a `test` directory that declares a top-level `main`.
/// A helper with no `main` is not a test file whatever it is called, which is why
/// `test/harness/…` files are not reported.
///
/// No quick-fix is offered: renaming a file is not an edit inside it, and any import of
/// it would have to change too.
class PreferCorrectTestFileName extends AligRule {
  /// Warns when a test file will not be collected.
  PreferCorrectTestFileName(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isUnderTestDirectory(resolver.path)) return;
    if (p.basename(resolver.path).endsWith('_test.dart')) return;

    context.registry.addFunctionDeclaration((node) {
      if (node.name.lexeme != 'main') return;
      if (node.parent is! CompilationUnit) return;

      reporter.atToken(node.name, code);
    });
  }
}

/// Whether [path] sits anywhere under a directory called `test`.
bool _isUnderTestDirectory(String path) =>
    p.split(p.dirname(path)).contains('test');
