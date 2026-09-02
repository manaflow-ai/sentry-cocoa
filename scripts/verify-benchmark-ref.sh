#!/usr/bin/env bash
set -euo pipefail

# Benchmark credentials are valid only for trusted release refs. Keep this check separate from
# the build so the policy is easy to exercise locally and fails closed when GitHub dispatches an
# unexpected event or ref.
event_name=${GITHUB_EVENT_NAME:-}
ref=${GITHUB_REF:-}

case "$event_name" in
  push|workflow_dispatch)
    ;;
  *)
    echo "Benchmarking is not allowed for event: ${event_name:-<unset>}" >&2
    exit 1
    ;;
esac

if [[ "$ref" == "refs/heads/main" ]]; then
  exit 0
fi

# Sentry release tags are plain SemVer tags, for example 9.24.0 or 9.24.0-rc.1.
if [[ "$ref" =~ ^refs/tags/[0-9]+\.[0-9]+\.[0-9]+([.+-][0-9A-Za-z.+-]+)?$ ]]; then
  exit 0
fi

echo "Benchmarking is not allowed for ref: ${ref:-<unset>}" >&2
exit 1
