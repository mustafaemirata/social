#!/usr/bin/env bash
# Usage: ./scripts/set_storage_cors.sh <firebase-project-id>
# If no project id supplied, uses current firebase default project via firebase CLI.
set -euo pipefail

PROJECT_ID="$1"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Please provide Firebase project id: ./scripts/set_storage_cors.sh <project-id>"
  exit 1
fi

BUCKET="gs://${PROJECT_ID}.appspot.com"

if ! command -v gsutil &> /dev/null; then
  echo "Error: gsutil not installed. Install Google Cloud SDK first." >&2
  exit 1
fi

echo "Applying CORS configuration to $BUCKET ..."

gsutil cors set "$(dirname "$0")/cors.json" "$BUCKET"

echo "CORS configuration set successfully."
