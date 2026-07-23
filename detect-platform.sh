#!/usr/bin/env bash
# Shared by bootstrap.sh and install-modern-tools.sh. Source it, then call
# detect_platform (echoes "macos" or "linux", exits on anything else).
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}
