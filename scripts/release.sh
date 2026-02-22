#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <version>"
  echo "  version  semver without 'v' prefix, e.g. 1.0.4"
  exit 1
}

[[ $# -eq 1 ]] || usage
version="$1"

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must be x.y.z format (got: $version)" >&2
  exit 1
fi

tag="v${version}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit or stash changes first." >&2
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  echo "Error: not on main branch (currently on '$branch')." >&2
  exit 1
fi

echo "Creating tag $tag..."
git tag "$tag"
echo "Pushing tag $tag to origin..."
git push origin "$tag"

echo ""
echo "Done. CI will run tests, build .deb/.rpm packages, and publish the GitHub Release."
echo "Track at: https://github.com/shay1987/images2zip/actions"
