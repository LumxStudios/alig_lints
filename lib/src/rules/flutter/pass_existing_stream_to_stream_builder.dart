import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/builder_sources.dart';

const _meta = AligRuleMeta(
  name: 'pass-existing-stream-to-stream-builder',
  category: 'flutter',
  problemMessage: 'This creates a new stream on every rebuild, so the old one is '
      'dropped mid-flight and the builder starts over.',
  correctionMessage: 'Create the stream once — in initState or a late final '
      'field — and pass that.',
  tags: ['correctness', 'performance', 'memory-leak'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a newly created stream is passed to a `StreamBuilder`.
///
/// ```dart
/// StreamBuilder<int>(
///   stream: ticks(),
///   builder: ...,
/// )
/// ```
/// Each rebuild produces a different stream, so `StreamBuilder` unsubscribes from
/// the old one and subscribes to the new. Events already delivered are lost and
/// the builder returns to `waiting`. Worse than with a future: a stream usually
/// owns something — a socket, a timer, a controller — and the abandoned one may
/// keep running, so the cost accumulates with every rebuild rather than repeating.
///
/// A name — a field, a local, `widget.stream` — is not reported: the value was
/// created somewhere else and survives the rebuild.
///
/// The reading of "freshly created" is shared with
/// `pass-existing-future-to-future-builder` through
/// `lib/src/common/builder_sources.dart`, so the two agree.
///
/// No quick-fix is offered. The repair moves the creation into `initState`, and a
/// stream held that way usually needs cancelling in `dispose` too — which the fix
/// could not write.
class PassExistingStreamToStreamBuilder extends AligRule {
  /// Warns when a `StreamBuilder`'s stream is rebuilt with the widget.
  PassExistingStreamToStreamBuilder(CustomLintConfigs configs)
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
      widget: 'StreamBuilder',
      argument: 'stream',
      libraryPath: 'widgets/async.dart',
    );
  }
}
