#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/release-docs.sh --tag v1.0.0 [--message "Release documentation v1.0.0"] [--skip-build]
  tools/release-docs.sh

Creates and pushes an annotated release tag for GitHub Pages deployment.
If --tag is omitted, the script reads the latest manual version from:
  manuals/sim300-iolink-modbus-server/manifest.json

Options:
  -t, --tag        Semantic version tag override, for example v1.0.0.
  -m, --message    Annotated tag message.
      --skip-build Skip local static-site build before tagging.
  -h, --help       Show this help.
EOF
}

tag=""
message=""
skip_build=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)
      tag="${2:-}"
      shift 2
      ;;
    -m|--message)
      message="${2:-}"
      shift 2
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$tag" ]]; then
        tag="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

manifest_path="$repo_root/manuals/sim300-iolink-modbus-server/manifest.json"

read_manifest_tag() {
  if ! command -v node >/dev/null 2>&1; then
    echo "Cannot read manifest latest version because node was not found." >&2
    echo "Install Node.js, or pass --tag explicitly." >&2
    exit 1
  fi

  node -e '
const fs = require("fs");
const manifestPath = process.argv[1];
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
if (!manifest.latest || typeof manifest.latest !== "string") {
  console.error("manifest.json is missing string field: latest");
  process.exit(1);
}
process.stdout.write(manifest.latest);
' "$manifest_path"
}

if [[ -z "$tag" ]]; then
  tag="$(read_manifest_tag)"
fi

if [[ ! "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Tag must use semantic format like v1.0.0" >&2
  exit 2
fi

if [[ -z "$message" ]]; then
  message="Release documentation $tag"
fi

run_build() {
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$repo_root/tools/Build-Site.ps1"
    return
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repo_root/tools/Build-Site.ps1"
    return
  fi

  echo "Cannot run tools/Build-Site.ps1 because neither pwsh nor powershell.exe was found." >&2
  echo "Install PowerShell, or rerun with --skip-build after building manually." >&2
  exit 1
}

if [[ "$skip_build" -eq 0 ]]; then
  run_build
fi

if ! git diff --exit-code >/dev/null; then
  echo "Working tree has unstaged changes. Commit them before tagging." >&2
  exit 1
fi

if ! git diff --cached --exit-code >/dev/null; then
  echo "Index has staged but uncommitted changes. Commit them before tagging." >&2
  exit 1
fi

git fetch origin --tags

if [[ -n "$(git tag --list "$tag")" ]]; then
  echo "Tag already exists locally: $tag" >&2
  exit 1
fi

if [[ -n "$(git ls-remote --tags origin "refs/tags/$tag")" ]]; then
  echo "Tag already exists on origin: $tag" >&2
  exit 1
fi

git tag -a "$tag" -m "$message"
git push origin "$tag"

echo "Pushed tag $tag. GitHub Actions should deploy GitHub Pages."
