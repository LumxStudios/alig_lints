import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/stringification.dart';

const _meta = AligRuleMeta(
  name: 'avoid-stream-tostring',
  category: 'common',
  problemMessage: "This prints the Stream itself — \"Instance of "
      "'Stream<...>'\" — rather than anything it carries.",
  correctionMessage: 'Listen to the stream, or await one of its values, and use '
      'that.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `Stream` is converted to a string.
///
/// ```dart
/// final events = source.stream;
/// print('events: $events');
/// ```
/// The output is `events: Instance of '_ControllerStream<int>'`. A stream is a
/// sequence that has not happened yet, so there is nothing for `toString` to
/// describe — and because nothing throws, the log reads as though it recorded
/// the data.
///
/// Both spellings are reported: the explicit `stream.toString()` and the
/// interpolation that calls it implicitly. Subtypes of `Stream` count too.
///
/// The reading of both spellings is shared with `avoid-future-tostring` through
/// `lib/src/common/stringification.dart`, so the two agree on what counts.
///
/// No quick-fix is offered. Turning a stream into text means deciding which of
/// its values to wait for — the first, all of them, the latest — and that is a
/// choice about what the message should say.
class AvoidStreamTostring extends AligRule {
  /// Warns when a stream is stringified.
  AvoidStreamTostring(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    reportStringificationsOf(
      context,
      reporter,
      code,
      matches: (type) => implementsType(type, (it) => it.isDartAsyncStream),
    );
  }
}
