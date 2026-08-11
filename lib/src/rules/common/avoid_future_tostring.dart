import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/stringification.dart';

const _meta = AligRuleMeta(
  name: 'avoid-future-tostring',
  category: 'common',
  problemMessage: "This prints the Future itself — \"Instance of 'Future<...>'\""
      ' — rather than the value it will produce.',
  correctionMessage: 'Await the future first, then use its value.',
  tags: ['correctness', 'cwe', 'async'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `Future` is converted to a string instead of awaited.
///
/// ```dart
/// final pending = load();
/// print('value: $pending');
/// ```
/// The output is `value: Instance of 'Future<int>'`. Nothing fails, nothing is
/// thrown, and the log looks like it worked — the missing `await` shows up only
/// when someone reads the line and finds no number in it.
///
/// Both spellings are reported: the explicit `future.toString()` and the
/// interpolation that calls it implicitly. Subtypes of `Future` count too, since
/// they carry the same defect.
///
/// This does not overlap with `avoid-default-tostring`, which skips abstract
/// types — `Future` is one, so only this rule reports it, and it can say what
/// the actual repair is.
///
/// No quick-fix is offered. Inserting `await` needs an async context that may
/// not exist at the call, and where the await belongs — around the interpolated
/// expression, or earlier at the point the future was created — depends on what
/// the surrounding code is doing.
class AvoidFutureTostring extends AligRule {
  /// Warns when a future is stringified rather than awaited.
  AvoidFutureTostring(CustomLintConfigs configs) : super(_meta, configs);

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
      matches: (type) => implementsType(type, (it) => it.isDartAsyncFuture),
    );
  }
}
