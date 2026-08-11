import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-iterable-of',
  category: 'common',
  problemMessage: 'from() accepts any iterable, so a wrong element type only '
      'shows up at runtime.',
  correctionMessage: 'Use of(), which checks the element type at compile time.',
  tags: ['correctness', 'cwe', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `List.from` is used where `List.of` would do.
///
/// `List<int>.from(strings)` compiles — `from` takes an `Iterable<dynamic>` — and
/// throws when the elements turn out to be the wrong type. `List<int>.of(strings)`
/// is rejected where it is written. The same holds for `Set` and `Map`.
///
/// The quick-fix is offered only when `of` would compile: when the source's
/// element type already fits. Where it would not — a `List<dynamic>` source, say
/// — the finding stands on its own, because that mismatch is the thing to fix and
/// a quick-fix should not hand back code that fails to build.
class PreferIterableOf extends AligRule {
  /// Warns when a `from` constructor should be `of`.
  PreferIterableOf(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isCoreCollectionFrom(node)) return;

      reporter.atNode(node.constructorName, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseOf()];
}

/// Whether [node] is `List.from`, `Set.from` or `Map.from`.
bool _isCoreCollectionFrom(InstanceCreationExpression node) {
  if (node.constructorName.name?.name != 'from') return false;

  final type = node.constructorName.type.type;
  if (type is! InterfaceType) return false;
  if (type.element.library.uri.scheme != 'dart') return false;

  return type.isDartCoreList || type.isDartCoreSet || type.isDartCoreMap;
}

/// Whether rewriting [node] to `of` would still compile.
///
/// `of` demands the source's elements already match, so a source whose element
/// type is `dynamic` — or is unrelated to the target's — would turn a runtime
/// failure into a build failure. That is progress, but not something to apply
/// behind a one-click fix.
bool _ofWouldCompile(InstanceCreationExpression node) {
  final target = node.constructorName.type.type;
  final arguments = node.argumentList.arguments;
  if (target is! InterfaceType || arguments.isEmpty) return false;

  final source = arguments.first.staticType;
  if (source is! InterfaceType) return false;

  final wanted = target.typeArguments;
  final given = _elementTypesOf(source);
  if (wanted.length != given.length) return false;

  for (var index = 0; index < wanted.length; index++) {
    if (!_fits(given[index], wanted[index])) return false;
  }

  return true;
}

/// The element types [source] yields, for a collection or an iterable.
List<DartType> _elementTypesOf(InterfaceType source) {
  if (source.isDartCoreMap) return source.typeArguments;

  // Not `firstWhere(..., orElse: () => source)`: `allSupertypes` is a
  // `List<InterfaceTypeImpl>` at runtime, so an `orElse` closure declared to
  // return `InterfaceType` fails the reified type check and throws — inside a
  // rule callback, where the exception is swallowed and the rule simply stops
  // reporting. See doc/API_NOTES.md.
  for (final supertype in source.allSupertypes) {
    if (supertype.isDartCoreIterable) return supertype.typeArguments;
  }

  return source.typeArguments;
}

/// Whether a value of type [given] is acceptable where [wanted] is required.
bool _fits(DartType given, DartType wanted) {
  if (given is DynamicType) return false;
  if (given == wanted) return true;
  if (given is! InterfaceType || wanted is! InterfaceType) return false;

  return given.allSupertypes.any(
    (supertype) => supertype.element == wanted.element,
  );
}

class _UseOf extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.sourceRange != diagnostic.sourceRange) return;
      if (!_isCoreCollectionFrom(node)) return;
      if (!_ofWouldCompile(node)) return;

      final name = node.constructorName.name!;

      final builder = reporter.createChangeBuilder(
        message: 'Use of()',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(
          SourceRange(name.offset, name.length),
          'of',
        );
      });
    });
  }
}
