#!/usr/bin/env bash
# Runs the whole verification gate, with the three slow suites in parallel.
#
# `dart test` and the two custom_lint runs are independent, so running them
# concurrently cuts the gate's wall time to roughly its slowest member. Each
# writes to its own log; the logs are printed only for the parts that failed.
set -uo pipefail

cd "$(dirname "$0")/.."

logs=$(mktemp -d)
trap 'rm -rf "$logs"' EXIT

# Regenerating first makes the gate self-consistent: a rule marked done in the
# manifest but missing from the registry would otherwise pass analyze and tests
# while never running in the golden suites.
if ! dart run tool/generate.dart >"$logs/generate" 2>&1; then
  printf 'FAIL  generate\n'
  sed 's/^/      /' "$logs/generate"
  exit 1
fi
sed 's/^/      /' "$logs/generate"

dart analyze >"$logs/analyze" 2>&1 &
analyze=$!

# The root analyze covers only this package. Without these two, a golden that
# does not compile still passes the gate: `dart run custom_lint` reports its own
# lints and stays quiet about the analyzer's errors.
#
# Warnings are not fatal here, deliberately. A golden for avoid-duplicate-map-keys
# contains duplicate map keys, and the analyzer warns about them on its own — that
# is the code being tested, not a defect. Only errors, which mean the golden does
# not compile, fail the gate.
(cd example && dart analyze --no-fatal-warnings) \
  >"$logs/analyze_example" 2>&1 &
analyze_example=$!

(cd example_flutter && dart analyze --no-fatal-warnings) \
  >"$logs/analyze_example_flutter" 2>&1 &
analyze_example_flutter=$!

dart test >"$logs/test" 2>&1 &
test_pid=$!

(cd example && dart run custom_lint) >"$logs/example" 2>&1 &
example=$!

(cd example_flutter && dart run custom_lint) >"$logs/example_flutter" 2>&1 &
example_flutter=$!

status=0
for pair in "analyze:$analyze" "analyze_example:$analyze_example" \
  "analyze_example_flutter:$analyze_example_flutter" "test:$test_pid" \
  "example:$example" "example_flutter:$example_flutter"; do
  name=${pair%%:*}
  pid=${pair##*:}
  if wait "$pid"; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name"
    sed 's/^/      /' "$logs/$name"
    status=1
  fi
done

# A single unambiguous verdict on the last line. Piping this script through
# `tail` hides its exit code from a following `&&`, so the verdict has to be
# visible in the output itself.
printf '%s\n' "$([ $status -eq 0 ] && echo 'GATE: PASS' || echo 'GATE: FAIL')"

exit $status
