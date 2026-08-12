import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-private-extension-type-field',
  category: 'common',
  problemMessage: 'The representation field is public, so callers can reach the '
      'underlying value and the wrapper stops meaning anything.',
  correctionMessage: 'Give the field a name starting with an underscore.',
  tags: ['maintainability', 'style'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an extension type's representation field is public.
///
/// ```dart
/// extension type Meters(int value) {}
/// ```
/// The point of an extension type is that a `Meters` is not an `int`. A public
/// representation field hands the `int` back to anyone who asks, so code that should
/// have had to go through the type's own API can reach around it — and once some of it
/// does, the type can no longer change what it wraps.
///
/// `extension type Meters(int _value)` keeps the wrapper meaningful: inside the
/// declaration the field is still available, and outside it there is only the API.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// Renaming the field to `_value` is a one-token edit here and a compile error at every
/// external `.value` — which is precisely the set of accesses the rule is pointing at.
/// They have to be dealt with first.
class PreferPrivateExtensionTypeField extends AligRule {
  /// Warns when the representation field is reachable from outside.
  PreferPrivateExtensionTypeField(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExtensionTypeDeclaration((node) {
      final field = node.representation.fieldName;
      if (field.lexeme.startsWith('_')) return;

      reporter.atToken(field, code);
    });
  }
}
