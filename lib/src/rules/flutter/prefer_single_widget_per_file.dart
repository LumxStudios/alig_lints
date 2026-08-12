import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'prefer-single-widget-per-file',
  category: 'flutter',
  problemMessage: 'This file already declares a widget, so the file no longer '
      'says what it contains.',
  correctionMessage: 'Move this widget to its own file.',
  tags: ['maintainability', 'style'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a file declares more than one widget.
///
/// One widget per file makes a file name an answer rather than a starting point:
/// finding `SubmitButton` means opening `submit_button.dart`, and a change to it
/// shows up in a diff whose path already says what changed. Files that accumulate
/// widgets tend to keep accumulating, and the second one is where that starts.
///
/// The **first** widget in the file is not reported — it is the one the file is
/// named for. Every widget after it is.
///
/// A `State` class is not counted: it belongs to the widget above it and has
/// nowhere else to live. Nor is any other class, so helpers, data classes and
/// enums beside a widget are fine.
///
/// No quick-fix is offered: moving a declaration to a new file means creating the
/// file, working out its imports, and adding an import wherever the widget was
/// used — none of which a single-file edit can do.
class PreferSingleWidgetPerFile extends AligRule {
  /// Warns on every widget after the first in a file.
  PreferSingleWidgetPerFile(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      var seen = 0;

      for (final declaration in unit.declarations) {
        if (declaration is! ClassDeclaration) continue;

        final element = declaration.declaredFragment?.element;
        // A State belongs to the widget it serves; it is not a second widget.
        if (!isWidgetSubclass(element) || isStateSubclass(element)) continue;

        seen++;
        // The first one is what the file is named for.
        if (seen > 1) reporter.atToken(declaration.name, code);
      }
    });
  }
}
