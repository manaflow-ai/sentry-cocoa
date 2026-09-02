#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "$0")" && pwd)/verify-benchmark-ref.sh"

assert_allowed() {
  local event_name=$1
  local ref=$2
  GITHUB_EVENT_NAME="$event_name" GITHUB_REF="$ref" "$script"
}

assert_rejected() {
  local event_name=$1
  local ref=$2
  if GITHUB_EVENT_NAME="$event_name" GITHUB_REF="$ref" "$script" >/dev/null 2>&1; then
    echo "Expected benchmark ref to be rejected: $event_name $ref" >&2
    exit 1
  fi
}

assert_allowed push refs/heads/main
assert_allowed workflow_dispatch refs/heads/main
assert_allowed workflow_dispatch refs/tags/9.24.0
assert_allowed push refs/tags/9.24.0-rc.1
assert_allowed workflow_dispatch refs/tags/9.24.0+build.7
assert_allowed workflow_dispatch refs/tags/9.24.0-rc.01a
assert_allowed workflow_dispatch refs/tags/9.24.0+build.007

assert_rejected pull_request refs/pull/42/merge
assert_rejected push refs/heads/v8.x
assert_rejected workflow_dispatch refs/heads/feature/benchmark
assert_rejected workflow_dispatch refs/tags/latest
assert_rejected workflow_dispatch refs/tags/9.24
assert_rejected workflow_dispatch refs/tags/9.24.0/attacker
assert_rejected workflow_dispatch refs/tags/01.24.0
assert_rejected workflow_dispatch refs/tags/9.24.0-01
assert_rejected workflow_dispatch refs/tags/9.24.0--
assert_rejected workflow_dispatch refs/tags/9.24.0..1
assert_rejected workflow_dispatch refs/tags/9.24.0-rc..1
assert_rejected workflow_dispatch refs/tags/9.24.0+

echo "Benchmark ref policy tests passed"
