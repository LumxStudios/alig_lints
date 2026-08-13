import 'dart:io';

import 'src/manifest.dart';

/// Lists every rule in a phase and its status.
///
/// Run from the package root: `dart run tool/list_phase.dart 1`
void main(List<String> args) {
  final phase = int.parse(args.single);
  final manifest = Manifest.load();
  final rules = manifest.forPhase(phase)
    ..sort((a, b) => a.name.compareTo(b.name));

  for (final rule in rules) {
    final mark = rule.isDone
        ? 'x'
        : rule.isCovered
            ? '~'
            : rule.isDeclined
                ? '-'
                : rule.needsSpec
                    ? '?'
                    : ' ';
    stdout.writeln('[$mark] ${rule.name}${rule.hasFix ? '  (has fix)' : ''}');
  }
  stdout.writeln(
    '\n${rules.where((r) => r.isSettled).length} / ${rules.length} settled in '
    'phase $phase  (x implemented, ~ covered by the analyzer, - deliberately '
    'not shipped, ? awaiting clarification).',
  );
}
