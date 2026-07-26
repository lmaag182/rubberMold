#!/usr/bin/env bash
# Backward-compatible wrapper — prefer ./export.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/export.sh" anim "$@"
