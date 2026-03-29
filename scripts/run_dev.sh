#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f ".env" ]]; then
  echo "Missing .env file in project root."
  echo "Create it from .env.example first."
  exit 1
fi

flutter run --dart-define-from-file=.env "$@"
