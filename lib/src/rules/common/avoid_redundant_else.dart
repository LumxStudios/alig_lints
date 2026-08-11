import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/control_flow_utils.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-redundant-else',
  category: 'common',
  problemMessage: 'The then branch always exits, so this else adds nesting '
      'without changing behaviour.',
  correctionMessage: 'Move the else body out of the else.',
  tags: ['control-flow', 'readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns about `else` blocks that can be removed without changing semantics.
///
/// When the `then` branch always leaves the enclosing block — `return`, `throw`,
/// `break`, `continue`, or a nested `if` whose own branches all do — control can
/// only reach the `else` body by falling past the `if`. Dropping the `else`
/// therefore keeps behaviour and removes a level of nesting.
///
/// Deliberately not reported: `else if` chains. Removing the `else` there splits
/// one chain into separate statements, which is a larger rewrite than this rule's
/// readability aim justifies.
class AvoidRedundantElse extends AligRule {
  /// Warns about `else` blocks that can be removed.
  AvoidRedundantElse(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      if (!_hasRedundantElse(node)) return;

      reporter.atToken(node.elseKeyword!, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UnwrapElse()];
}

bool _hasRedundantElse(IfStatement node) {
  final elseStatement = node.elseStatement;
  if (elseStatement == null) return false;
  if (elseStatement is IfStatement) return false;

  return alwaysExits(node.thenStatement);
}

class _UnwrapElse extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addIfStatement((node) {
      final elseKeyword = node.elseKeyword;
      if (elseKeyword == null) return;
      if (elseKeyword.offset != diagnostic.offset) return;
      if (!_hasRedundantElse(node)) return;

      final elseStatement = node.elseStatement!;
      final indent = indentationOf(node, resolver);

      final body = elseStatement is Block
          ? reindentedBody(elseStatement, indent, resolver)
          : elseStatement.toSource();
      if (body.isEmpty) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the else',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Replaces everything from the end of the then branch — the ` else {`,
        // the body, and the closing brace — with the body at the `if`'s own
        // indentation.
        fileBuilder.addSimpleReplacement(
          SourceRange(
            node.thenStatement.end,
            elseStatement.end - node.thenStatement.end,
          ),
          '\n$indent$body',
        );
      });
    });
  }
}
