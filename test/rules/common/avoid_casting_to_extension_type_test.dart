import 'package:alig_lints/src/rules/common/avoid_casting_to_extension_type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidCastingToExtensionType(CustomLintConfigs.empty);

  test('reports casts to an extension type, not casts away from one', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_casting_to_extension_type.dart',
      onLines: [8, 9, 10, 11],
    );
  });

  test('fix wraps only where the constructor call is guaranteed to compile',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_casting_to_extension_type.dart',
      expectedPath:
          'test/fixtures/common/avoid_casting_to_extension_type.expected.dart',
    );
  });
}
