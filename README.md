# alig_lints

Custom analysis rules for Dart and Flutter, built on [`custom_lint`], plus a
bundled selection of built-in Dart lints.

[`custom_lint`]: https://pub.dev/packages/custom_lint

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  alig_lints:
    path: ../alig_linter
```

```yaml
# analysis_options.yaml
include: package:alig_lints/all.yaml
```

Then run `dart pub get` and restart the analysis server in your IDE.
Command line: `dart run custom_lint`.

### Presets

| Preset | Contents |
|---|---|
| `package:alig_lints/all.yaml` | Built-in lints + every implemented rule |
| `package:alig_lints/recommended.yaml` | Built-in lints + `warning`-severity rules only |
| `package:alig_lints/flutter.yaml` | Built-in lints + Flutter rules only |
| `package:alig_lints/dart_lints.yaml` | Built-in Dart lints only, no plugin |

### Turning a rule off, or changing its severity

```yaml
custom_lint:
  rules:
    - -avoid-unnecessary-setstate      # disable
    - avoid-self-assignment:
        severity: info                 # downgrade
```

Rules can also be suppressed inline with `// ignore: avoid-self-assignment`
or per file with `// ignore_for_file: avoid-self-assignment`.

## Progress

<!-- progress:start -->
**87 / 181 rules implemented** — 5 awaiting clarification, 5 covered by the analyzer itself

| Phase | Done |
|---|---|
| 1 | 19 / 21 |
| 2 | 17 / 18 |
| 3 | 31 / 32 |
| 4 | 16 / 16 |
| 5 | 8 / 22 |
| 6 | 0 / 8 |
| 7 | 1 / 22 |
| 8 | 0 / 7 |
| 9 | 0 / 35 |
<!-- progress:end -->

Rules implemented with documented approximations are listed in
[`doc/LIMITATIONS.md`](doc/LIMITATIONS.md). Rules whose intent could not be
inferred from the available specification are listed in
[`doc/UNCLEAR.md`](doc/UNCLEAR.md).

## Development

- `tool/rules_manifest.json` is the source of truth and the work queue.
- `dart run tool/next.dart` prints the next rule to implement.
- `dart run tool/list_phase.dart <n>` shows one phase's status.
- `dart run tool/generate.dart` regenerates `lib/src/registry.dart`, the
  presets and the table above. `tool/verify.sh` runs it first, so marking a rule
  done in the manifest is enough.
- `./tool/verify.sh` is the full gate: analyze, tests and both golden suites,
  run in parallel. Prints the log only for the parts that failed, and ends with
  `GATE: PASS` or `GATE: FAIL`. Do not chain a commit after a piped run of it —
  the pipe hides the exit code, so read the verdict line instead.
- Individually: `dart analyze`, `dart test`,
  `(cd example && dart run custom_lint)` for the `common` rule goldens, and
  `(cd example_flutter && dart run custom_lint)` for the Flutter ones.
- `doc/API_NOTES.md` records verified analyzer/custom_lint API details.
