import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-state-constructors',
  category: 'flutter',
  problemMessage: 'A State constructor runs before its widget is attached, so '
      'nothing here can see the widget or the context.',
  correctionMessage: 'Move the work to initState.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `State` has a constructor with a body.
///
/// ```dart
/// class _SampleState extends State<Sample> {
///   _SampleState() {
///     counter = widget.initial;  // widget is not set yet
///   }
/// }
/// ```
/// Flutter creates the `State` first and attaches it afterwards, so during the
/// constructor `widget` and `context` are not available. Reading `widget` there
/// throws; reading anything derived from it silently gets the wrong value. The
/// framework provides `initState` for exactly this work, and it runs once, after
/// attachment.
///
/// Only a **non-empty** body is reported. `_SampleState();` and a constructor that
/// only forwards to initialisers are fine — the objection is to work being done at
/// a point where the State cannot see what it belongs to.
///
/// No quick-fix is offered. Moving statements into `initState` means creating it
/// if absent and putting `super.initState()` first, and if the class already has
/// one, deciding where in it the moved code belongs.
class AvoidStateConstructors extends AligRule {
  /// Warns when a `State` constructor does work.
  AvoidStateConstructors(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((node) {
      final owner = node.parent;
      if (owner is! ClassDeclaration) return;
      if (!isStateSubclass(owner.declaredFragment?.element)) return;

      final body = node.body;
      if (body is! BlockFunctionBody) return;
      if (body.block.statements.isEmpty) return;

      for (final statement in body.block.statements) {
        reporter.atNode(statement, code);
      }
    });
  }
}
