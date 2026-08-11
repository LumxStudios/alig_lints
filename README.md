# alig_lints

Custom analysis rules for Dart and Flutter, reimplementing the DCM
"recommended" rule set on top of [`custom_lint`], plus a bundled selection of
built-in Dart lints.

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
**35 / 181 rules implemented** — 3 awaiting clarification

| Phase | Done |
|---|---|
| 1 | 19 / 21 |
| 2 | 15 / 18 |
| 3 | 0 / 32 |
| 4 | 0 / 16 |
| 5 | 0 / 22 |
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
  presets and the table above.
- `dart test` runs unit and fix-golden tests.
- `(cd example && dart run custom_lint)` checks the `common` rule goldens.
- `(cd example_flutter && dart run custom_lint)` checks the Flutter rule
  goldens.
- `doc/API_NOTES.md` records verified analyzer/custom_lint API details.
