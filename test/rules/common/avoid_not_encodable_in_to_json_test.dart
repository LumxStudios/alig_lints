import 'package:alig_lints/src/rules/common/avoid_not_encodable_in_to_json.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports values the encoder cannot convert, not ones with toJson',
      () async {
    await expectRuleReports(
      AvoidNotEncodableInToJson(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_not_encodable_in_to_json.dart',
      onLines: [40, 41, 42, 43],
    );
  });
}
