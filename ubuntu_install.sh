#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
installer="$repo_root/install-modern-tools.sh"

if [[ ! -x "$installer" ]]; then
  echo "Missing executable installer: $installer" >&2
  exit 1
fi

echo "ubuntu_install.sh is a compatibility wrapper."
echo "Using the unified installer: ./install-modern-tools.sh"
"$installer" "$@"
