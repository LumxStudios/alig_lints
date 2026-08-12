import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'prefer-overriding-parent-equality',
  category: 'common',
  problemMessage: 'The parent defines == and hashCode, so this class compares by the '
      "parent's fields and ignores its own.",
  correctionMessage: 'Override == and hashCode to include this class\'s fields.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a subclass inherits equality that ignores its own fields.
///
/// ```dart
/// class Base {
///   Base(this.id);
///   final int id;
///   @override bool operator ==(Object other) => other is Base && other.id == id;
///   @override int get hashCode => id.hashCode;
/// }
///
/// class Child extends Base {
///   Child(super.id, this.label);
///   final String label;
/// }
/// ```
/// Two `Child`s with the same `id` and different `label`s are equal, and hash to the
/// same bucket. Put them in a `Set` and one disappears; use one as a `Map` key and it
/// finds the other. Nothing about the code at those places looks wrong, and the class
/// that caused it does not mention equality at all — which is the whole difficulty.
///
/// Reported when an ancestor declares **both** `==` and `hashCode`, this class declares
/// neither, and this class adds at least one instance field of its own. A subclass that
/// adds no fields inherits equality correctly and is not reported.
///
/// **Flutter widgets are excluded.** `Widget` overrides both members to restore identity
/// semantics — the framework decides whether two widgets match with `canUpdate`, not with
/// `==` — so a widget that leaves them alone is behaving correctly. The general form of
/// that exception is recorded in `doc/LIMITATIONS.md`: any ancestor whose `==` delegates
/// to `super` produces the same false positive, and the body of an inherited member is not
/// visible from here.
///
/// No quick-fix is offered. Generating `==` and `hashCode` means choosing which fields
/// identify the value — the inherited ones as well as the new ones — and whether the
/// comparison should accept subtypes. Those are the decisions the missing override was
/// supposed to record.
class PreferOverridingParentEquality extends AligRule {
  /// Warns when a subclass leaves the parent's equality in place.
  PreferOverridingParentEquality(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;
      if (_declaresEquality(node)) return;
      // With no fields of its own, the inherited comparison is still right.
      if (!_addsInstanceField(node)) return;
      if (!_ancestorDefinesEquality(element)) return;
      // Flutter's Widget overrides both to restore identity semantics — the framework
      // compares widgets with canUpdate, not ==. Asking a widget to define value
      // equality would be wrong advice, and the gate caught this on four goldens.
      if (isWidgetSubclass(element)) return;

      reporter.atToken(node.name, code);
    });
  }
}

/// Whether [node] declares both halves of equality itself.
bool _declaresEquality(ClassDeclaration node) {
  var hasEquals = false;
  var hasHashCode = false;

  for (final member in node.members) {
    if (member is! MethodDeclaration) continue;
    if (member.name.lexeme == '==') hasEquals = true;
    if (member.name.lexeme == 'hashCode') hasHashCode = true;
  }

  return hasEquals || hasHashCode;
}

/// Whether [node] adds an instance field that equality would have to consider.
bool _addsInstanceField(ClassDeclaration node) {
  for (final member in node.members) {
    if (member is FieldDeclaration && !member.isStatic) return true;
  }

  return false;
}

/// Whether an ancestor of [element] declares both `==` and `hashCode`.
bool _ancestorDefinesEquality(InterfaceElement element) {
  for (final supertype in element.allSupertypes) {
    final ancestor = supertype.element;
    // Object's own pair is identity, which is what everything starts with.
    if (ancestor.name == 'Object') continue;

    final hasEquals = ancestor.methods.any((method) => method.name == '==');
    final hasHashCode = ancestor.getters.any((getter) => getter.name == 'hashCode');
    if (hasEquals && hasHashCode) return true;
  }

  return false;
}
