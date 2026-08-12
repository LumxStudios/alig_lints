import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/builder_sources.dart';

const _meta = AligRuleMeta(
  name: 'pass-existing-future-to-future-builder',
  category: 'flutter',
  problemMessage: 'This creates a new future on every rebuild, so the operation '
      'restarts and the builder falls back to its loading state each time.',
  correctionMessage: 'Create the future once — in initState or a late final '
      'field — and pass that.',
  tags: ['correctness', 'performance'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a newly created future is passed to a `FutureBuilder`.
///
/// ```dart
/// FutureBuilder<int>(
///   future: load(),
///   builder: ...,
/// )
/// ```
/// `build` runs whenever anything above this widget changes. Each run calls
/// `load()` again, so `FutureBuilder` sees a different future, discards what it
/// had, and starts from `ConnectionState.waiting` — the spinner reappears, and the
/// request is made again. Nothing errors; the screen just flickers and the server
/// gets hit repeatedly for reasons unrelated to the data.
///
/// The future has to outlive the build. A `late final` field assigned in
/// `initState` is the usual answer, which is also why this rule so often means a
/// `StatelessWidget` needs to become stateful.
///
/// A name — a field, a local, `widget.future` — is not reported: the value was
/// created somewhere else and survives the rebuild. A conditional counts as fresh
/// only if one of its branches is.
///
/// The reading of "freshly created" is shared with
/// `pass-existing-stream-to-stream-builder` through
/// `lib/src/common/builder_sources.dart`, so the two agree.
///
/// No quick-fix is offered. The repair moves the call into `initState`, which
/// means adding the field, and often converting the widget to a `StatefulWidget`
/// first.
class PassExistingFutureToFutureBuilder extends AligRule {
  /// Warns when a `FutureBuilder`'s future is rebuilt with the widget.
  PassExistingFutureToFutureBuilder(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    reportFreshBuilderSource(
      context,
      reporter,
      code,
      widget: 'FutureBuilder',
      argument: 'future',
      libraryPath: 'widgets/async.dart',
    );
  }
}
