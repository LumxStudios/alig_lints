import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-match-file-name',
  category: 'common',
  problemMessage: 'This file declares one thing and is not named after it, so its path '
      'does not say what is in it.',
  correctionMessage: 'Rename the file to the declaration in snake_case.',
  tags: ['style', 'maintainability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a file declaring one thing is not named after it.
///
/// ```
/// lib/helpers.dart      // declares only `SubmitButton`
/// lib/submit_button.dart
/// ```
/// A file name is the cheapest index a codebase has. When it matches, finding
/// `SubmitButton` means opening `submit_button.dart` and a diff's path already says what
/// changed; when it does not, every reader falls back to searching.
///
/// **Only files declaring exactly one type are reported** — a class, mixin, enum, extension,
/// extension type or typedef. That is the one case where "the name should match" has a
/// single answer. A file with two types has no one name to take, and a file whose only
/// declaration is a function is not expected to be named after it, which is what the
/// catalogue means by *the class name*. Functions beside the type do not change the answer.
///
/// The comparison is against the declaration's name in snake_case, so `SubmitButton` pairs
/// with `submit_button.dart`. A private declaration is compared without its underscore.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced: renaming
/// a file is not an edit inside it, and every import of it has to change too.
class PreferMatchFileName extends AligRule {
  /// Warns when a single declaration's file is named something else.
  PreferMatchFileName(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      // Types only. The catalogue describes this as matching the *class* name, and a
      // file whose one declaration is a function — `main`, a helper — is not expected to
      // be named after it.
      final types = unit.declarations
          .whereType<NamedCompilationUnitMember>()
          .where(_isTypeDeclaration)
          .toList();
      if (types.length != 1) return;
      // A type beside other declarations still names the file; a second type does not.
      final only = types.single;

      final expected = _snakeCaseOf(only.name.lexeme);
      if (p.basenameWithoutExtension(resolver.path) == expected) return;

      reporter.atToken(only.name, code);
    });
  }
}

/// Whether [declaration] is a type, which is what a file is named after.
bool _isTypeDeclaration(NamedCompilationUnitMember declaration) =>
    declaration is ClassDeclaration ||
    declaration is MixinDeclaration ||
    declaration is EnumDeclaration ||
    declaration is ExtensionTypeDeclaration ||
    declaration is TypeAlias;

/// [name] as a file name would spell it: `SubmitButton` becomes `submit_button`.
String _snakeCaseOf(String name) {
  final trimmed = name.startsWith('_') ? name.substring(1) : name;
  final words = trimmed.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match[0]!.toLowerCase()}',
  );

  return words.startsWith('_') ? words.substring(1) : words;
}
