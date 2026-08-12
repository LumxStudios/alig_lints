import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/disposal.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'dispose-fields',
  category: 'flutter',
  problemMessage: 'This field owns something disposable and the State never '
      'disposes it, so it outlives the widget.',
  correctionMessage: 'Dispose it in the State\'s dispose method.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `State` field holding something disposable is never disposed.
///
/// ```dart
/// class _SampleState extends State<Sample> {
///   final _notifier = ValueNotifier<int>(0);
///   // no dispose, or a dispose that misses this field
/// }
/// ```
/// Controllers, notifiers and focus nodes hold listeners, animation tickers and
/// platform resources. When the widget goes away and the field is not disposed,
/// those stay — the ticker keeps requesting frames, the listeners keep the disposed
/// `State` reachable, and each rebuild of the parent adds another one.
///
/// **A missing `dispose` method counts.** The framework always calls `dispose` on a
/// `State`, so there is no version of this where the teardown belongs somewhere
/// else — which is what separates this rule from `dispose-class-fields`, where a
/// class with no teardown method at all is a design choice rather than a defect.
/// The two never report the same field: that one skips `State` subclasses.
///
/// "Disposable" means the field's type declares `dispose`. A `StreamSubscription`
/// is released with `cancel` and a `Sink` with `close`, and the analyzer's own
/// `cancel_subscriptions` and `close_sinks` report those — so keying on `dispose`
/// keeps this from being a second warning on the same field.
///
/// All three spellings of the teardown count: `field.dispose()`,
/// `field?.dispose()` and `field..dispose()`.
///
/// No quick-fix is offered. Adding the call means creating `dispose` when it is
/// absent, putting `super.dispose()` last, and ordering the calls against whatever
/// else is already there.
class DisposeFields extends AligRule {
  /// Warns when a `State` leaks a disposable field.
  DisposeFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!isStateSubclass(node.declaredFragment?.element)) return;

      final disposed = _disposedNamesIn(node);

      for (final field in _disposableFieldsOf(node)) {
        if (disposed.contains(field.name.lexeme)) continue;

        reporter.atToken(field.name, code);
      }
    });
  }
}

/// The names disposed by the class's own `dispose` method, empty when it has none.
Set<String> _disposedNamesIn(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
      return disposedNamesIn(member.body);
    }
  }

  return const {};
}

/// The instance fields whose type declares `dispose`.
List<VariableDeclaration> _disposableFieldsOf(ClassDeclaration node) => [
      for (final member in node.members)
        if (member is FieldDeclaration && !member.isStatic)
          for (final field in member.fields.variables)
            if (isDisposable(field.declaredFragment?.element.type)) field,
    ];
