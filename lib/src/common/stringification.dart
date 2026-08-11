import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Reports every place a value is turned into a string: the explicit
/// `toString()` call, and the interpolation that calls it implicitly.
///
/// [matches] decides which values are of interest. Shared by the rules that
/// object to stringifying a particular kind of value — a `Future`, a `Stream` —
/// so that they agree on which spellings count, rather than drifting apart as
/// one of them learns about a case the other does not.
void reportStringificationsOf(
  CustomLintContext context,
  DiagnosticReporter reporter,
  LintCode code, {
  required bool Function(DartType? type) matches,
}) {
  context.registry.addMethodInvocation((node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final target = node.realTarget;
    if (target == null || !matches(target.staticType)) return;

    reporter.atNode(node, code);
  });

  context.registry.addInterpolationExpression((node) {
    if (!matches(node.expression.staticType)) return;

    reporter.atNode(node, code);
  });
}

/// Whether [type] is an interface type that satisfies [test], either directly or
/// through something it implements.
bool implementsType(DartType? type, bool Function(InterfaceType) test) {
  if (type is! InterfaceType) return false;
  if (test(type)) return true;

  for (final supertype in type.allSupertypes) {
    if (test(supertype)) return true;
  }

  return false;
}
