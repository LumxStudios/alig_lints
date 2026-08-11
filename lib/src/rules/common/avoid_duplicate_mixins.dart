import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-mixins',
  category: 'common',
  problemMessage: 'This mixin is already applied elsewhere in the hierarchy, so '
      'applying it here has no effect.',
  correctionMessage: 'Remove the mixin from this declaration.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `with` clause applies a mixin that the hierarchy already has.
///
/// Catches both a mixin listed twice in the same clause and a mixin already
/// applied anywhere up the `extends` chain, however many levels above.
///
/// Applies to `class` and `enum` declarations, the two kinds that carry a `with`
/// clause.
class AvoidDuplicateMixins extends AligRule {
  /// Warns when a mixin is applied more than once in a hierarchy.
  AvoidDuplicateMixins(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(WithClause? withClause, NamedType? superclass) {
      if (withClause == null) return;

      final inherited = _mixinsAppliedBy(superclass);
      final seen = <Element>{};

      for (final mixinType in withClause.mixinTypes) {
        final element = mixinType.element;
        if (element == null) continue;

        if (inherited.contains(element) || !seen.add(element)) {
          reporter.atNode(mixinType, code);
        }
      }
    }

    context.registry.addClassDeclaration((node) {
      check(node.withClause, node.extendsClause?.superclass);
    });
    context.registry.addEnumDeclaration((node) => check(node.withClause, null));
  }

  @override
  List<Fix> getFixes() => [_RemoveDuplicateMixin()];
}

/// Every mixin and interface the declaration named by [superclass] already
/// brings in.
///
/// Mixin application inserts each mixin into the supertype chain, so a
/// superclass's `allSupertypes` covers mixins applied at any depth above it.
Set<Element> _mixinsAppliedBy(NamedType? superclass) {
  final element = superclass?.element;
  if (element is! InterfaceElement) return const {};

  return {
    element,
    for (final type in element.allSupertypes) type.element,
  };
}

class _RemoveDuplicateMixin extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    void check(WithClause? withClause) {
      if (withClause == null) return;

      for (final mixinType in withClause.mixinTypes) {
        if (mixinType.sourceRange != diagnostic.sourceRange) continue;

        // A `with` clause needs at least one mixin, so when the duplicate is the
        // only entry the whole clause goes rather than just the type.
        final isOnlyMixin = withClause.mixinTypes.length == 1;

        final builder = reporter.createChangeBuilder(
          message: isOnlyMixin
              ? 'Remove the redundant with clause'
              : 'Remove the duplicate mixin',
          priority: 80,
        );
        builder.addDartFileEdit((fileBuilder) {
          fileBuilder.addDeletion(
            isOnlyMixin
                ? rangeWithLeadingSpace(withClause, resolver)
                : rangeRemovingListItem(mixinType, resolver),
          );
        });
      }
    }

    context.registry.addClassDeclaration((node) => check(node.withClause));
    context.registry.addEnumDeclaration((node) => check(node.withClause));
  }
}
