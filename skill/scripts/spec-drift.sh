#!/usr/bin/env bash
# Usage: spec-drift.sh [args] — alias for spec-check.sh (same flags, same output).
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/spec-check.sh" "$@"
