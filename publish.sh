#!/usr/bin/env bash
# publish.sh — one-command release script for the GC Private Markets Dashboard
#
# Usage:
#   ./publish.sh dashboard 1.1.0 "fixes cashflow display in private credit funds"
#   ./publish.sh tracker 5.2 "adds Vintage Year column to Investments tab"
#
# What it does:
#   1. Validates inputs (version format, message present)
#   2. Bumps the version constant inside index.html (for dashboard releases)
#   3. Updates version.json with the new version + note + URL
#   4. Updates CHANGELOG.md with a new entry
#   5. Rebuilds the offline ZIP bundle
#   6. Commits everything to git, tags, and pushes to GitHub
#   7. Prints what to do next
#
# The first time you run this, set USERNAME below to your GitHub username so
# version.json's URLs are correct.

set -euo pipefail

# ─────────── CONFIG ───────────
USERNAME="jocelynrenaud-commits"     # set me — your GitHub username
REPO="growth-circle-dashboard"  # the repo name
# ──────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

KIND="${1:-}"
NEW_VER="${2:-}"
NOTE="${3:-}"

usage() {
  cat <<USAGE
Usage:
  ./publish.sh dashboard <version> "<note>"     # dashboard release
  ./publish.sh tracker <version> "<note>"       # tracker template release
  ./publish.sh bundle                           # rebuild offline ZIP without bumping versions
  ./publish.sh check                            # verify repo state without pushing

Examples:
  ./publish.sh dashboard 1.1.0 "fixes cashflow display in private credit funds"
  ./publish.sh tracker 5.2 "adds Vintage Year column"

Version format: semver-ish, e.g. 1.0.0, 1.1.0, 5.2, 5.2.1
USAGE
  exit 1
}

require_clean_tree() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "✗ Working tree has uncommitted changes. Commit or stash them first."
    git status --short
    exit 1
  fi
}

bump_dashboard_version() {
  # Replace the dashboard version string inside index.html.
  # The line we're targeting looks like:  dashboard: '1.0.0',
  if ! grep -q "dashboard: '" index.html; then
    echo "✗ Couldn't find dashboard version in index.html"
    exit 1
  fi
  sed -i.bak -E "s/(dashboard: ')[^']+(',  *\/\/ bumped by publish\.sh)/\1$1\2/" index.html
  if ! grep -q "dashboard: '$1'" index.html; then
    # Fallback: try without the trailing comment
    sed -i.bak -E "s/(dashboard: ')[^']+(')/\1$1\2/" index.html
  fi
  rm -f index.html.bak
  echo "  ✓ Bumped dashboard to $1 in index.html"
}

bump_tracker_version() {
  # Update the embedded tracker version constant in index.html
  sed -i.bak -E "s/(tracker: ')[^']+(')/\1$1\2/" index.html
  rm -f index.html.bak
  echo "  ✓ Updated tracker version to $1 in index.html"
}

update_manifest() {
  # Rewrites version.json with current dashboard + tracker versions.
  local dash="$1" track="$2" dash_note="$3" track_note="$4"
  local today; today="$(date -u +%Y-%m-%d)"
  cat > version.json <<JSON
{
  "_comment": "Single source of truth for current version numbers. Do not edit manually — use ./publish.sh.",
  "dashboard": "$dash",
  "dashboard_url": "https://$USERNAME.github.io/$REPO/",
  "dashboard_note": "$dash_note",

  "tracker": "$track",
  "tracker_url": "https://$USERNAME.github.io/$REPO/releases/GC_Investment_Tracker_v$track.xlsx",
  "tracker_note": "$track_note",

  "offline_bundle_url": "https://$USERNAME.github.io/$REPO/releases/GC_Private_Markets_Dashboard.zip",
  "guide_url": "https://$USERNAME.github.io/$REPO/releases/SETUP_GUIDE.docx",

  "released_at": "$today"
}
JSON
  echo "  ✓ Updated version.json"
}

read_current_versions() {
  CURRENT_DASH=$(grep -oE "\"dashboard\": \"[^\"]+\"" version.json | head -1 | sed 's/.*: "\(.*\)"/\1/')
  CURRENT_TRACK=$(grep -oE "\"tracker\": \"[^\"]+\"" version.json | head -1 | sed 's/.*: "\(.*\)"/\1/')
  CURRENT_DASH_NOTE=$(grep -oE "\"dashboard_note\": \"[^\"]+\"" version.json | head -1 | sed 's/.*: "\(.*\)"/\1/')
  CURRENT_TRACK_NOTE=$(grep -oE "\"tracker_note\": \"[^\"]+\"" version.json | head -1 | sed 's/.*: "\(.*\)"/\1/')
}

prepend_changelog() {
  local kind="$1" ver="$2" note="$3"
  local today; today="$(date -u +%Y-%m-%d)"
  local label
  if [[ "$kind" == "dashboard" ]]; then
    label="Dashboard $ver"
  else
    label="Tracker $ver"
  fi

  # Insert a new entry under "## [Unreleased]"
  local tmp; tmp="$(mktemp)"
  awk -v label="$label" -v today="$today" -v note="$note" '
    BEGIN { inserted = 0 }
    /^## \[Unreleased\]/ {
      print
      print ""
      print "Things being worked on — not yet shipped."
      print ""
      print "---"
      print ""
      print "## " label " — " today
      print ""
      print "- " note
      inserted = 1
      # Skip the original "Things being worked on" line + blank
      getline; getline; getline; getline
      next
    }
    { print }
  ' CHANGELOG.md > "$tmp" && mv "$tmp" CHANGELOG.md
  echo "  ✓ Prepended changelog entry"
}

rebuild_bundle() {
  local track_ver="$1"
  local stage; stage="$(mktemp -d)"
  cp index.html "$stage/GC_Private_Markets_Dashboard.html"
  cp "releases/GC_Investment_Tracker_v$track_ver.xlsx" "$stage/GC_Investment_Tracker.xlsx"
  cp releases/SETUP_GUIDE.docx "$stage/"
  (cd "$stage" && zip -q GC_Private_Markets_Dashboard.zip \
    GC_Private_Markets_Dashboard.html GC_Investment_Tracker.xlsx SETUP_GUIDE.docx)
  mv "$stage/GC_Private_Markets_Dashboard.zip" releases/
  rm -rf "$stage"
  echo "  ✓ Rebuilt offline bundle ZIP"
}

archive_old_tracker() {
  local old_ver="$1" new_ver="$2"
  if [[ "$old_ver" != "$new_ver" && -f "releases/GC_Investment_Tracker_v$old_ver.xlsx" ]]; then
    mv "releases/GC_Investment_Tracker_v$old_ver.xlsx" "releases/archive/"
    echo "  ✓ Archived previous tracker to releases/archive/"
  fi
}

# ─────────── CHECK MODE ───────────
if [[ "$KIND" == "check" ]]; then
  echo "Repository state check"
  echo "─────────────────────"
  read_current_versions
  echo "Current dashboard version: $CURRENT_DASH"
  echo "Current tracker version:   $CURRENT_TRACK"
  echo
  echo "Files present:"
  for f in index.html version.json README.md CHANGELOG.md publish.sh \
           "releases/GC_Investment_Tracker_v$CURRENT_TRACK.xlsx" \
           releases/SETUP_GUIDE.docx \
           releases/GC_Private_Markets_Dashboard.zip; do
    if [[ -e "$f" ]]; then echo "  ✓ $f"; else echo "  ✗ MISSING: $f"; fi
  done
  echo
  if [[ "$USERNAME" == "YOUR_GH_USERNAME" ]]; then
    echo "⚠  Set USERNAME at the top of publish.sh before publishing."
  fi
  exit 0
fi

# ─────────── BUNDLE-ONLY MODE ───────────
if [[ "$KIND" == "bundle" ]]; then
  read_current_versions
  rebuild_bundle "$CURRENT_TRACK"
  echo "Bundle rebuilt. Don't forget to commit:"
  echo "  git add releases/GC_Private_Markets_Dashboard.zip"
  echo "  git commit -m 'rebuild offline bundle' && git push"
  exit 0
fi

# ─────────── RELEASE MODE ───────────
if [[ -z "$KIND" || -z "$NEW_VER" || -z "$NOTE" ]]; then usage; fi
if [[ "$KIND" != "dashboard" && "$KIND" != "tracker" ]]; then
  echo "✗ Kind must be 'dashboard' or 'tracker' (got '$KIND')"
  usage
fi
if [[ ! "$NEW_VER" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "✗ Version must look like 1.2.3 or 5.1 (got '$NEW_VER')"
  exit 1
fi

# Sanity checks
if [[ "$USERNAME" == "YOUR_GH_USERNAME" ]]; then
  echo "✗ Set USERNAME at the top of publish.sh before publishing."
  exit 1
fi
require_clean_tree

read_current_versions
echo "Current: dashboard=$CURRENT_DASH, tracker=$CURRENT_TRACK"
echo "Releasing: $KIND v$NEW_VER — $NOTE"
echo

if [[ "$KIND" == "dashboard" ]]; then
  if [[ "$NEW_VER" == "$CURRENT_DASH" ]]; then
    echo "✗ Dashboard is already at $NEW_VER. Pick a higher version."
    exit 1
  fi
  bump_dashboard_version "$NEW_VER"
  update_manifest "$NEW_VER" "$CURRENT_TRACK" "$NOTE" "$CURRENT_TRACK_NOTE"
  prepend_changelog "dashboard" "$NEW_VER" "$NOTE"
  rebuild_bundle "$CURRENT_TRACK"
else
  if [[ "$NEW_VER" == "$CURRENT_TRACK" ]]; then
    echo "✗ Tracker is already at $NEW_VER. Pick a higher version."
    exit 1
  fi
  # The new tracker file must already be in releases/
  if [[ ! -f "releases/GC_Investment_Tracker_v$NEW_VER.xlsx" ]]; then
    echo "✗ Expected file releases/GC_Investment_Tracker_v$NEW_VER.xlsx — not found."
    echo "   Save the new tracker there first, then re-run."
    exit 1
  fi
  archive_old_tracker "$CURRENT_TRACK" "$NEW_VER"
  bump_tracker_version "$NEW_VER"
  update_manifest "$CURRENT_DASH" "$NEW_VER" "$CURRENT_DASH_NOTE" "$NOTE"
  prepend_changelog "tracker" "$NEW_VER" "$NOTE"
  rebuild_bundle "$NEW_VER"
fi

# Stage, commit, tag, push
git add -A
git status --short

echo
echo "Commit message:"
TAG=""
if [[ "$KIND" == "dashboard" ]]; then
  COMMIT_MSG="release dashboard v$NEW_VER: $NOTE"
  TAG="dashboard-v$NEW_VER"
else
  COMMIT_MSG="release tracker v$NEW_VER: $NOTE"
  TAG="tracker-v$NEW_VER"
fi
echo "  $COMMIT_MSG"
echo "Tag: $TAG"
echo
read -p "Commit and push to GitHub? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted. Working tree has staged changes; review with 'git status' or revert with 'git reset --hard HEAD'."
  exit 0
fi

git commit -m "$COMMIT_MSG"
git tag "$TAG"
git push origin main
git push origin "$TAG"

echo
echo "✓ Released $KIND v$NEW_VER"
echo
echo "GitHub Pages will redeploy automatically (~30-60 seconds)."
echo "Verify at: https://$USERNAME.github.io/$REPO/"
echo "Members will see the update banner on their next visit."
