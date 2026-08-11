import 'dart:io';

import 'src/manifest.dart';

/// Prints the next rule to implement, as guidance for the implementer.
///
/// Run from the package root: `dart run tool/next.dart`
void main() {
  final manifest = Manifest.load();
  final rule = manifest.next;

  if (rule == null) {
    stdout.writeln('All rules are done or awaiting clarification.');
    return;
  }

  stdout.writeln('''
name        : ${rule.name}
phase       : ${rule.phase}
category    : ${rule.category}
severity    : ${rule.severity}
tags        : ${rule.tags.join(', ')}
has fix     : ${rule.hasFix}
configurable: ${rule.configurable}
description : ${rule.description}

implement   : ${rule.libPath}
unit test   : ${rule.testPath}
golden      : ${rule.goldenPath}

remaining   : ${manifest.todo.length} of ${manifest.rules.length}
''');
}
