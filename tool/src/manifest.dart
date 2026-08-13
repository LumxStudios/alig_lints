import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// One rule as described by `tool/rules_manifest.json`.
class RuleEntry {
  /// Reads one rule entry out of the manifest JSON.
  RuleEntry.fromJson(Map<String, Object?> json)
      : name = json['name']! as String,
        category = json['category']! as String,
        description = json['description']! as String,
        tags = (json['tags']! as List).cast<String>(),
        hasFix = json['hasFix']! as bool,
        configurable = json['configurable']! as bool,
        severity = json['severity']! as String,
        phase = json['phase']! as int,
        status = json['status']! as String,
        needsSpec = json['needsSpec']! as bool,
        notes = json['notes']! as String;

  /// Kebab-case rule name, e.g. `avoid-self-assignment`.
  final String name;

  /// Either `common` or `flutter`.
  final String category;

  /// One-line description of the rule — the available specification.
  final String description;

  /// Classification tags, e.g. `correctness`.
  final List<String> tags;

  /// Whether the rule is expected to offer an auto-fix.
  final bool hasFix;

  /// Whether the rule takes options.
  final bool configurable;

  /// Either `warning` or `info`.
  final String severity;

  /// Implementation phase, 1 to 9.
  final int phase;

  /// One of `todo`, `done`, `covered`, or `declined`.
  ///
  /// `covered` means the analyzer already reports this exactly, so implementing
  /// the rule would only add a second message. Those rules have no file of their
  /// own; `doc/LIMITATIONS.md` records which diagnostic covers each.
  ///
  /// `declined` means the rule is deliberately not shipped — the advice was not
  /// wanted here. The entry stays in the catalogue so the decision is recorded
  /// rather than looking like an oversight, and [notes] says why. Like `covered`,
  /// these rules have no file of their own and are never picked up as work again.
  String status;

  /// Whether the rule's intent could not be inferred and awaits clarification.
  bool needsSpec;

  /// Free-form notes, holding the open question when [needsSpec] is set.
  String notes;

  /// `avoid-self-assignment` -> `avoid_self_assignment`
  String get fileName => name.replaceAll('-', '_');

  /// `avoid-self-assignment` -> `AvoidSelfAssignment`
  String get className => name
      .split('-')
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();

  /// Whether this rule is implemented in this package.
  bool get isDone => status == 'done';

  /// Whether the analyzer already reports this, so no rule is written.
  bool get isCovered => status == 'covered';

  /// Whether this rule is deliberately not shipped.
  bool get isDeclined => status == 'declined';

  /// Whether this rule needs no further work, whoever reports it — including a
  /// decision not to ship it, which is as settled as an implementation.
  bool get isSettled => isDone || isCovered || isDeclined;

  /// Relative path of this rule's implementation file.
  String get libPath => 'lib/src/rules/$category/$fileName.dart';

  /// Relative path of this rule's unit test.
  String get testPath => 'test/rules/$category/${fileName}_test.dart';

  /// Relative path of this rule's `expect_lint` golden.
  String get goldenPath =>
      '${category == 'flutter' ? 'example_flutter' : 'example'}'
      '/lib/$category/$fileName.dart';

  /// Serializes this entry back to manifest JSON.
  Map<String, Object?> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'tags': tags,
        'hasFix': hasFix,
        'configurable': configurable,
        'severity': severity,
        'phase': phase,
        'status': status,
        'needsSpec': needsSpec,
        'notes': notes,
      };
}

/// The rule catalogue: source of truth and work queue.
class Manifest {
  Manifest._(this._path, this._source, this.rules);

  /// Path of the manifest relative to the package root.
  static const fileName = 'tool/rules_manifest.json';

  /// Loads the manifest, searching upwards from the current directory so that
  /// this works from both the package root and `tool/`.
  static Manifest load() {
    var dir = Directory.current;
    while (true) {
      final candidate = File(p.join(dir.path, fileName));
      if (candidate.existsSync()) {
        final json =
            jsonDecode(candidate.readAsStringSync()) as Map<String, Object?>;
        final rules = (json['rules']! as List)
            .cast<Map<String, Object?>>()
            .map(RuleEntry.fromJson)
            .toList();

        return Manifest._(candidate.path, json, rules);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('Could not find $fileName above ${Directory.current}');
      }
      dir = parent;
    }
  }

  final String _path;
  final Map<String, Object?> _source;

  /// Every rule in the catalogue.
  final List<RuleEntry> rules;

  /// The rules belonging to [phase].
  List<RuleEntry> forPhase(int phase) =>
      rules.where((r) => r.phase == phase).toList();

  /// The rules that are implemented.
  List<RuleEntry> get done => rules.where((r) => r.isDone).toList();

  /// The rules still to implement, excluding those awaiting clarification and
  /// those the analyzer already covers.
  List<RuleEntry> get todo =>
      rules.where((r) => !r.isSettled && !r.needsSpec).toList();

  /// The rules the analyzer already reports.
  List<RuleEntry> get covered => rules.where((r) => r.isCovered).toList();

  /// The rules deliberately not shipped.
  List<RuleEntry> get declined => rules.where((r) => r.isDeclined).toList();

  /// The next rule to implement: lowest phase first, then alphabetical.
  RuleEntry? get next {
    final pending = todo
      ..sort(
        (a, b) =>
            a.phase != b.phase ? a.phase - b.phase : a.name.compareTo(b.name),
      );

    return pending.isEmpty ? null : pending.first;
  }

  /// Writes the catalogue back to disk, preserving unrelated top-level keys.
  void save() {
    final json = {
      ..._source,
      'rules': [for (final rule in rules) rule.toJson()],
    };
    File(_path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }
}
