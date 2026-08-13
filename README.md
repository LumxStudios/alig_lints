# alig_lints

Custom analysis rules for Dart and Flutter, built on [`custom_lint`], plus a
curated selection of the built-in Dart lints. One dependency and one `include:`
line give you both halves, so this replaces a shared-lint package as well.

Every rule reports something that compiles and runs, and is wrong anyway: a value
the type system cannot catch, a listener nothing removes, a default that depends on
how a variable was declared. Where a rule cannot establish that from one file, it
says so in its own documentation rather than guessing.

[`custom_lint`]: https://pub.dev/packages/custom_lint

## Install

```yaml
# pubspec.yaml
dev_dependencies:
  custom_lint: ^0.8.1
  alig_lints:
    git: https://github.com/LumxStudios/alig_lints.git
```

The repository is public, so the git dependency needs no token or SSH key. To pin
a version, add `ref:` with a tag or commit. Working on the rules themselves? Use a
path dependency instead:

```yaml
  alig_lints:
    path: ../alig_lints
```

```yaml
# analysis_options.yaml
include: package:alig_lints/all.yaml
```

Then run `dart pub get` and restart the analysis server in your IDE.
Command line: `dart run custom_lint`.

Verified from a clean Flutter project, through the git dependency above: both
halves work off the single `include:` — the custom rules and the bundled built-in
lints alike.

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
    - avoid-unnecessary-setstate: false  # disable
    - avoid-self-assignment:
        severity: info                 # downgrade
```

Rules can also be suppressed inline with `// ignore: avoid-self-assignment`
or per file with `// ignore_for_file: avoid-self-assignment`.

## Progress

<!-- progress:start -->
**159 / 181 rules implemented** — 7 awaiting clarification, 10 covered elsewhere, 5 deliberately not shipped

| Theme | Settled |
|---|---|
| Structural equality | 19 / 21 |
| Unnecessary and redundant code | 17 / 18 |
| Conditions, control flow, patterns | 31 / 32 |
| Collections and Iterable members | 16 / 16 |
| Nullability, toString, casts | 21 / 22 |
| Async and futures | 8 / 8 |
| Flutter widgets and life cycle | 22 / 22 |
| Disposal and memory leaks | 7 / 7 |
| Unused code, naming, style | 33 / 35 |
<!-- progress:end -->

**What the numbers mean.** *Implemented* rules each have a golden that asserts
where they fire and where they do not. *Covered elsewhere* means the defect is
already reported — by an analyzer warning that is on by default, by a built-in
lint this package enables, or by a sibling rule here — and was verified by
measurement rather than assumed; a second rule would only put two warnings on one
line. *Awaiting clarification* means the rule's name and description did not
settle what it should report, most often because the whole rule is a configured
name or list; guessing would have produced a rule that either never fires or
fires on correct code. *Deliberately not shipped* means the rule worked and was
dropped anyway, because the advice was not worth its volume; the catalogue keeps
the entry and `tool/rules_manifest.json` records the reason for each.

Every rule's own doc comment states what it deliberately does **not** report, and
why. That is the first place to look when a rule surprises you.

## Development

- `tool/rules_manifest.json` is the source of truth and the work queue.
- `dart run tool/next.dart` prints the next rule to implement.
- `dart run tool/list_phase.dart <n>` shows one phase's status.
- `dart run tool/generate.dart` regenerates `lib/src/registry.dart`, the
  presets and the table above. `tool/verify.sh` runs it first, so marking a rule
  done in the manifest is enough.
- `./tool/verify.sh` is the full gate, run in parallel: `dart analyze` here and in
  each golden package, `dart test`, and `dart run custom_lint` in each golden
  package. It prints the log only for the parts that failed and ends with
  `GATE: PASS` or `GATE: FAIL`. Do not chain a commit after a piped run of it —
  the pipe hides the exit code, so read the verdict line instead.
- Golden packages, each a real package that path-depends on this one:
  - `example/` — the `common` rules. `example/test/` holds the goldens for rules
    that need to be under a `test` directory.
  - `example_flutter/` — the Flutter rules.
  - `example_single_widget/` — `prefer-single-widget-per-file`. It cannot be
    verified in the other packages, whose goldens deliberately group several
    widgets per file, and disabling a rule in the package that holds its golden
    would silence its own `expect_lint` checks too.
- A golden must **compile**. The gate analyses each golden package for errors, so
  a golden that does not build fails it — warnings are allowed, since a golden for
  `avoid-duplicate-map-keys` contains duplicate map keys on purpose.
- An `expect_lint` comment goes on the line immediately before the **reported**
  line, which for a rule that reports on a method's name is between the
  annotation and the signature.
- When a rule has a fix, check that the fix's output **compiles**. Two fixes in
  this package produced code that did not, and only compiling the result showed
  it.
