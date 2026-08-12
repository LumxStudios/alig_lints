import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-incomplete-copy-with',
  category: 'flutter',
  problemMessage: 'This copyWith cannot change every field the constructor '
      'takes, so callers have to rebuild the object by hand for the rest.',
  correctionMessage: 'Add a parameter for each of the constructor\'s named '
      'parameters.',
  tags: ['correctness', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `copyWith` omits parameters the default constructor accepts.
///
/// ```dart
/// class Incomplete {
///   const Incomplete({required this.name, required this.count, this.label});
///
///   Incomplete copyWith({String? name}) => ...;
/// }
/// ```
/// A `copyWith` is read as "everything, with these changed". When one field is
/// missing, code that needs to change it either constructs the object from scratch
/// — duplicating the argument list, which then drifts — or, worse, silently keeps
/// the old value because the author assumed the method covered it.
///
/// The gap almost always appears later: a field is added to the constructor and
/// `copyWith` is not updated, which is exactly when nothing complains.
///
/// Only the **named** parameters of the unnamed constructor are compared. A
/// positional constructor has no names to match, so those classes are not reported.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// Adding a parameter to the signature is half the change: the body has to pass it
/// on, and the `name ?? this.name` shape a fix would guess is wrong for any field
/// whose null is a real value — which is the case where getting it wrong is hardest
/// to notice.
class AvoidIncompleteCopyWith extends AligRule {
  /// Warns when `copyWith` is missing constructor parameters.
  AvoidIncompleteCopyWith(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final copyWith = _copyWithOf(node);
      final constructor = _unnamedConstructorOf(node);
      if (copyWith == null || constructor == null) return;

      final expected = _namedParameterNamesOf(constructor.parameters);
      if (expected.isEmpty) return;

      final actual = _namedParameterNamesOf(copyWith.parameters);
      if (expected.difference(actual).isEmpty) return;

      reporter.atToken(copyWith.name, code);
    });
  }
}

MethodDeclaration? _copyWithOf(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'copyWith') {
      return member;
    }
  }

  return null;
}

ConstructorDeclaration? _unnamedConstructorOf(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is ConstructorDeclaration && member.name == null) return member;
  }

  return null;
}

Set<String> _namedParameterNamesOf(FormalParameterList? parameters) => {
      for (final parameter in parameters?.parameters ?? const <FormalParameter>[])
        if (parameter.isNamed) parameter.name?.lexeme ?? '',
    }..remove('');
