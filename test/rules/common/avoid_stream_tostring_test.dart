import 'package:alig_lints/src/rules/common/avoid_stream_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports streams stringified explicitly and by interpolation', () async {
    await expectRuleReports(
      AvoidStreamTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_stream_tostring.dart',
      onLines: [6, 7, 8],
    );
  });
}
