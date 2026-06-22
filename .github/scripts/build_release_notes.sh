#!/usr/bin/env bash
# Builds RELEASE_NOTES.md for a tagged release: the curated CHANGELOG.md
# section for this version (if one exists) plus the raw commit log since
# the previous tag, as a fallback/appendix.
set -euo pipefail

VERSION="${1:?usage: build_release_notes.sh vX.Y.Z}"
PREV_TAG="$(git tag --sort=-v:refname | grep -v "^${VERSION}$" | head -n1 || true)"

{
  echo "## ${VERSION}"
  echo

  if [ -f CHANGELOG.md ] && grep -q "^## \[${VERSION}\]" CHANGELOG.md; then
    awk -v ver="## [${VERSION}]" '
      $0 ~ "^## \\[" { if (found) exit; if (index($0, ver) == 1) { found=1; next } }
      found { print }
    ' CHANGELOG.md
    echo
  fi

  echo "### Commits"
  echo
  if [ -n "$PREV_TAG" ]; then
    git log "${PREV_TAG}..${VERSION}" --pretty=format:"- %s (%h)" --no-merges
    echo
    echo
    echo "Full diff: https://github.com/KnightRider2070/heliograph/compare/${PREV_TAG}...${VERSION}"
  else
    git log "${VERSION}" --pretty=format:"- %s (%h)" --no-merges
  fi
  echo
} > RELEASE_NOTES.md

echo "version=${VERSION}" >> "${GITHUB_OUTPUT:-/dev/null}"

cat RELEASE_NOTES.md
