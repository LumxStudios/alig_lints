import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-redundant-pragma-inline',
  category: 'common',
  problemMessage: 'This annotation has no effect here: there is no function body '
      'for the VM to inline.',
  correctionMessage: 'Remove the annotation, or move it to a function with a '
      'body.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// The pragma this rule is about.
const _preferInline = 'vm:prefer-inline';

/// Warns when `@pragma('vm:prefer-inline')` is attached to something the VM
/// cannot inline.
///
/// The pragma asks the VM to inline a function body at its call sites, so it does
/// nothing when there is no body to inline or the target is not a function at
/// all. Reported cases:
/// - abstract or `external` methods and functions, which have no body;
/// - classes, mixins, enums, extensions and typedefs;
/// - fields and top-level variables.
///
/// Getters, setters, constructors and ordinary methods are left alone: all of
/// them have bodies the VM can inline.
///
/// Other pragmas are not this rule's concern.
class AvoidRedundantPragmaInline extends AligRule {
  /// Warns when a prefer-inline pragma cannot take effect.
  AvoidRedundantPragmaInline(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAnnotation((node) {
      if (!_isPreferInline(node)) return;
      if (!_hasNoInlinableBody(node.parent)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemovePragma()];
}

/// Whether [node] is `@pragma('vm:prefer-inline')`.
bool _isPreferInline(Annotation node) {
  if (node.name.name != 'pragma') return false;

  final arguments = node.arguments?.arguments;
  if (arguments == null || arguments.isEmpty) return false;

  final first = arguments.first;

  return first is SimpleStringLiteral && first.value == _preferInline;
}

/// Whether [declaration] has no function body for the VM to inline.
bool _hasNoInlinableBody(AstNode? declaration) => switch (declaration) {
      MethodDeclaration(:final isAbstract, :final externalKeyword) =>
        isAbstract || externalKeyword != null,
      FunctionDeclaration(:final externalKeyword) => externalKeyword != null,
      ClassDeclaration() => true,
      MixinDeclaration() => true,
      EnumDeclaration() => true,
      ExtensionDeclaration() => true,
      ExtensionTypeDeclaration() => true,
      ClassTypeAlias() => true,
      FunctionTypeAlias() => true,
      GenericTypeAlias() => true,
      FieldDeclaration() => true,
      TopLevelVariableDeclaration() => true,
      _ => false,
    };

class _RemovePragma extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addAnnotation((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the annotation',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(lineRangeOf(node, resolver));
      });
    });
  }
}
