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

# Validate plain SemVer tags without relying on a permissive expression. Core and numeric
# prerelease identifiers cannot have leading zeroes; all identifiers must be non-empty.
is_valid_semver_tag() {
  local tag=${SEMVER_TAG:-}
  local core_and_prerelease=${tag#refs/tags/}
  local core=$core_and_prerelease
  local prerelease=''
  local build=''
  local identifier
  local -a core_parts prerelease_parts build_parts

  [[ "$tag" == refs/tags/* && "$core_and_prerelease" != "$tag" ]] || return 1
  [[ "$core_and_prerelease" != *+*+* ]] || return 1

  if [[ "$core_and_prerelease" == *+* ]]; then
    core=${core_and_prerelease%%+*}
    build=${core_and_prerelease#*+}
    [[ -n "$build" && "$build" != .* && "$build" != *. && "$build" != *..* ]] || return 1
    IFS='.' read -r -a build_parts <<< "$build"
    for identifier in "${build_parts[@]}"; do
      [[ "$identifier" =~ ^[0-9A-Za-z-]+$ ]] || return 1
    done
  fi

  if [[ "$core" == *-* ]]; then
    prerelease=${core#*-}
    core=${core%%-*}
    [[ -n "$prerelease" && "$prerelease" != .* && "$prerelease" != *. && "$prerelease" != *..* ]] || return 1
    IFS='.' read -r -a prerelease_parts <<< "$prerelease"
    for identifier in "${prerelease_parts[@]}"; do
      [[ "$identifier" =~ ^[0-9A-Za-z-]+$ ]] || return 1
      [[ ! "$identifier" =~ ^0[0-9]+$ ]] || return 1
      [[ ! "$identifier" =~ ^-+$ ]] || return 1
    done
  fi

  [[ "$core" != .* && "$core" != *. && "$core" != *..* ]] || return 1
  IFS='.' read -r -a core_parts <<< "$core"
  (( ${#core_parts[@]} == 3 )) || return 1
  for identifier in "${core_parts[@]}"; do
    [[ "$identifier" =~ ^(0|[1-9][0-9]*)$ ]] || return 1
  done
}

# Sentry release tags are plain SemVer tags, for example 9.24.0 or 9.24.0-rc.1.
SEMVER_TAG=$ref
if is_valid_semver_tag; then
  exit 0
fi

echo "Benchmarking is not allowed for ref: ${ref:-<unset>}" >&2
exit 1
