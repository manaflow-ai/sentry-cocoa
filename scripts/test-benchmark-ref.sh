#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/verify-benchmark-ref.sh"
test_event_name=''
test_ref=''

assert_allowed() {
  GITHUB_EVENT_NAME="$test_event_name" GITHUB_REF="$test_ref" "$script"
}

assert_rejected() {
  if GITHUB_EVENT_NAME="$test_event_name" GITHUB_REF="$test_ref" "$script" >/dev/null 2>&1; then
    echo "Expected benchmark ref to be rejected: $test_event_name $test_ref" >&2
    exit 1
  fi
}

allowed_cases=(
  'push refs/heads/main'
  'workflow_dispatch refs/heads/main'
  'workflow_dispatch refs/tags/9.24.0'
  'push refs/tags/9.24.0-rc.1'
  'workflow_dispatch refs/tags/9.24.0+build.7'
  'workflow_dispatch refs/tags/9.24.0-rc.01a'
  'workflow_dispatch refs/tags/9.24.0+build.007'
)
for case_spec in "${allowed_cases[@]}"; do
  read -r test_event_name test_ref <<< "$case_spec"
  assert_allowed
done

rejected_cases=(
  'pull_request refs/pull/42/merge'
  'push refs/heads/v8.x'
  'workflow_dispatch refs/heads/feature/benchmark'
  'workflow_dispatch refs/tags/latest'
  'workflow_dispatch refs/tags/9.24'
  'workflow_dispatch refs/tags/9.24.0/attacker'
  'workflow_dispatch refs/tags/01.24.0'
  'workflow_dispatch refs/tags/9.24.0-01'
  'workflow_dispatch refs/tags/9.24.0--'
  'workflow_dispatch refs/tags/9.24.0..1'
  'workflow_dispatch refs/tags/9.24.0-rc..1'
  'workflow_dispatch refs/tags/9.24.0+'
)
for case_spec in "${rejected_cases[@]}"; do
  read -r test_event_name test_ref <<< "$case_spec"
  assert_rejected
done

echo "Benchmark ref policy tests passed"
