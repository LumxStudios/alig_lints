import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/disposal.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'dispose-class-fields',
  category: 'common',
  problemMessage: 'The class has a teardown method that does not release this '
      'field, so whatever it holds is never let go.',
  correctionMessage: 'Dispose the field in the teardown method.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// The names a class uses for the method that releases what it owns.
const _teardownNames = {'dispose', 'close'};

/// Warns when a class's teardown method misses one of its disposable fields.
///
/// ```dart
/// class Owner {
///   final Resource forgotten = Resource();
///   final Resource released = Resource();
///
///   void dispose() {
///     released.dispose();
///   }
/// }
/// ```
/// The teardown method is a promise that calling it releases everything. A field it
/// skips is worse than one in a class with no teardown at all, because callers who
/// do the right thing still leak — and the class looks like it handles this.
///
/// A class with **no** teardown method is not reported. Whether the object should own
/// a lifecycle is a design decision, and demanding one wherever a disposable field
/// appears would report plenty of code that is correct: a field passed in from
/// outside is the caller's to dispose.
///
/// **`State` subclasses are skipped**, and go to `dispose-fields` instead. The
/// framework always calls `dispose` there, so a missing method is itself the defect —
/// a different rule with a different answer. The two never report the same field.
///
/// "Disposable" means the field's type declares `dispose`. Fields released with
/// `cancel` or `close` — subscriptions and sinks — are the analyzer's own
/// `cancel_subscriptions` and `close_sinks` to report.
///
/// No quick-fix is offered: where in the teardown the call belongs depends on the
/// order the other releases need.
class DisposeClassFields extends AligRule {
  /// Warns when a teardown method leaves a disposable field behind.
  DisposeClassFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      // A State's missing dispose is dispose-fields' business, not this rule's.
      if (isStateSubclass(node.declaredFragment?.element)) return;

      final teardown = _teardownOf(node);
      if (teardown == null) return;

      final disposed = disposedNamesIn(teardown.body);

      for (final field in _disposableFieldsOf(node)) {
        if (disposed.contains(field.name.lexeme)) continue;

        reporter.atToken(field.name, code);
      }
    });
  }
}

MethodDeclaration? _teardownOf(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is MethodDeclaration &&
        _teardownNames.contains(member.name.lexeme)) {
      return member;
    }
  }

  return null;
}

List<VariableDeclaration> _disposableFieldsOf(ClassDeclaration node) => [
      for (final member in node.members)
        if (member is FieldDeclaration && !member.isStatic)
          for (final field in member.fields.variables)
            if (isDisposable(field.declaredFragment?.element.type)) field,
    ];
