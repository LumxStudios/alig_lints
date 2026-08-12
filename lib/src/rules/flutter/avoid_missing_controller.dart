import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-missing-controller',
  category: 'flutter',
  problemMessage: 'Nothing here can read what the user types: there is no '
      'controller and no callback.',
  correctionMessage: 'Add a controller, or one of onChanged, onSaved or '
      'onFieldSubmitted.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// The ways a text field can hand its value back.
const _valueChannels = {
  'controller',
  'onChanged',
  'onSaved',
  'onSubmitted',
  'onFieldSubmitted',
  'onEditingComplete',
};

/// Warns when a text field offers no way to get its value.
///
/// ```dart
/// TextField()
/// ```
/// The user can type into it and the app can never find out what they typed. It
/// renders, it accepts input, it looks finished — and the value goes nowhere. This
/// is almost always an unfinished widget rather than a deliberate read-only field,
/// which would say so with `readOnly: true`.
///
/// Satisfied by a `controller` or by any of the callbacks that carry the value:
/// `onChanged`, `onSaved`, `onSubmitted`, `onFieldSubmitted`, `onEditingComplete`.
/// One is enough.
///
/// Reported for `TextField`, `TextFormField` and `EditableText`, which are the three
/// the catalogue names.
///
/// No quick-fix is offered: a controller has to be created, stored and disposed
/// somewhere, and a callback needs a body — neither is an edit at the call site.
class AvoidMissingController extends AligRule {
  /// Warns when a text field's value has nowhere to go.
  AvoidMissingController(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isTextField(node.staticType)) return;

      final passed = {
        for (final argument in node.argumentList.arguments)
          if (argument is NamedExpression) argument.name.label.name,
      };
      if (passed.intersection(_valueChannels).isNotEmpty) return;

      reporter.atNode(node.constructorName, code);
    });
  }
}

bool _isTextField(DartType? type) {
  if (type is! InterfaceType) return false;

  return hasFlutterSupertype(type.element, 'TextField', 'material/text_field.dart') ||
      hasFlutterSupertype(
        type.element,
        'TextFormField',
        'material/text_form_field.dart',
      ) ||
      hasFlutterSupertype(
        type.element,
        'EditableText',
        'widgets/editable_text.dart',
      );
}
