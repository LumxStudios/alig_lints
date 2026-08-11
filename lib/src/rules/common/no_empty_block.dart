import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'no-empty-block',
  category: 'common',
  problemMessage: 'This block is empty, so the statement around it does nothing.',
  correctionMessage: 'Fill the block in, or remove the statement.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns about empty statement blocks.
///
/// An empty `if`, loop or `try` body is either an unfinished thought or a
/// statement whose whole effect is its condition — both worth a second look.
///
/// Three kinds of empty block are left alone, each because it is a normal way to
/// write something:
/// - **Catch clauses.** An empty catch deliberately swallows an exception, and
///   Dart's own `empty_catches` reports it already.
/// - **Function, method and constructor bodies.** No-op callbacks and empty
///   constructors are ordinary; `empty_constructor_bodies` covers the latter.
/// - **Blocks containing only comments** are still empty to the parser, and are
///   reported: a comment explaining why nothing happens belongs with a statement,
///   not instead of one.
class NoEmptyBlock extends AligRule {
  /// Warns about empty statement blocks.
  NoEmptyBlock(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      if (node.statements.isNotEmpty) return;
      if (!_isStatementBlock(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [node] is a block belonging to a statement rather than to a catch
/// clause or a function body.
bool _isStatementBlock(Block node) => switch (node.parent) {
      CatchClause() => false,
      BlockFunctionBody() => false,
      _ => true,
    };
