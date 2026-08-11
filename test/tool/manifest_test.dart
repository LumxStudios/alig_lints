import 'package:test/test.dart';

import '../../tool/src/manifest.dart';

void main() {
  final manifest = Manifest.load();

  test('loads all 181 rules from the manifest', () {
    expect(manifest.rules, hasLength(181));
  });

  test('derives Dart file and class names from kebab-case rule names', () {
    final rule =
        manifest.rules.firstWhere((r) => r.name == 'avoid-self-assignment');

    expect(rule.fileName, 'avoid_self_assignment');
    expect(rule.className, 'AvoidSelfAssignment');
    expect(rule.category, 'common');
    expect(rule.hasFix, isTrue);
    expect(rule.severity, 'warning');
  });

  test('every rule is in a known category and phase', () {
    for (final rule in manifest.rules) {
      expect(rule.category, anyOf('common', 'flutter'), reason: rule.name);
      expect(rule.phase, inInclusiveRange(1, 9), reason: rule.name);
    }
  });
}
