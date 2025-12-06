#!/bin/bash
set -e

# Generate comprehensive release notes from git history
# This captures ALL commits since last release, not just chart updates

CHANGELOG_FILE="CHANGELOG.md"
RELEASE_NOTES_FILE=".release-notes.md"
# Run this when the helm chart update PR is merged into master
NEW_TAG=$(cat VERSION)

# Get the previous tag
PREVIOUS_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$PREVIOUS_TAG" ]; then
    echo "No previous tag found, using all commits"
    COMMIT_RANGE="HEAD"
else
    echo "Generating release notes since $PREVIOUS_TAG..$NEW_TAG"
    COMMIT_RANGE="$PREVIOUS_TAG..HEAD"
fi

# Initialize arrays for categorization
declare -a FEATURES
declare -a BUG_FIXES
declare -a CONFIG_CHANGES
declare -a OTHER_CHANGES

get_updates() {
  git log --format='%B' -n 1 "$short_hash" | sed -n "/### ${1} Version Upgrades/,/^$/p" | grep '^-' | sed "s/^- /- ($short_hash) /"
}

# Process commits
while IFS= read -r commit; do
    # Get commit message (first line only)
    message=$(git log --format=%s -n 1 "$commit")
    short_hash=$(git log --format=%h -n 1 "$commit")

    # Skip merge commits
    if [[ $message =~ ^Merge ]]; then
      continue
    fi

    # Skip chart update commits (they're handled separately)
    if [[ $message =~ [Uu]pdate.*helm.*chart ]] || [[ $message =~ chore:.*helm.*chart ]]; then
      MAJOR_CHART_UPDATES=$(get_updates 'Major' "$short_hash")
      MINOR_CHART_UPDATES=$(get_updates 'Minor' "$short_hash")
      PATCH_CHART_UPDATES=$(get_updates 'Patch' "$short_hash")
    fi

    formatted_message="- $short_hash $message"

    # Categorize commits
    if [[ $message =~ ^feat ]]; then
        FEATURES+=("$formatted_message")
    elif [[ $message =~ ^fix ]]; then
        BUG_FIXES+=("$formatted_message")
    elif [[ $message =~ ^chore ]]; then
        CONFIG_CHANGES+=("$formatted_message")
    else
        OTHER_CHANGES+=("$formatted_message")
    fi
done < <(git rev-list "$COMMIT_RANGE")

function get_total_chart_updates() {
  git log --format='%B' -n 1 "$short_hash" | grep -c Update
}

TOTAL_CHART_UPDATES=get_total_chart_updates

cat $CHANGELOG_FILE | tail -n +5 > $CHANGELOG_FILE.tmp

# Generate release notes file
{
  printf '%s\n' "## KubeAid Release Version ${NEW_TAG}"
  echo ""

   if [ -n "$MAJOR_CHART_UPDATES" ]; then
     echo "### Major Version Upgrades"
     printf '%s\n' "${MAJOR_CHART_UPDATES}"
     echo ""
   fi

   if [ -n "$MINOR_CHART_UPDATES" ]; then
     echo "### Minor Version Upgrades"
     printf '%s\n' "${MINOR_CHART_UPDATES}"
     echo ""
   fi

   if [ -n "$PATCH_CHART_UPDATES" ]; then
     echo "### Patch Version Upgrades"
     printf '%s\n' "${PATCH_CHART_UPDATES}"
     echo ""
   fi

   if [ ${#FEATURES[@]} -gt 0 ]; then
       echo "### Features"
       printf '%s\n' "${FEATURES[@]}"
       echo ""
   fi

   if [ ${#BUG_FIXES[@]} -gt 0 ]; then
       echo "### Bug Fixes"
       printf '%s\n' "${BUG_FIXES[@]}"
       echo ""
   fi

   if [ ${#CONFIG_CHANGES[@]} -gt 0 ]; then
       echo "### Configuration Changes"
       printf '%s\n' "${CONFIG_CHANGES[@]}"
       echo ""
   fi

   if [ ${#OTHER_CHANGES[@]} -gt 0 ]; then
       echo "### Other Changes"
       printf '%s\n' "${OTHER_CHANGES[@]}"
       echo ""
   fi

   # If no commits categorized, add a note
   total=$((TOTAL_CHART_UPDATES + ${#FEATURES[@]} + ${#BUG_FIXES[@]} + ${#CONFIG_CHANGES[@]} + ${#OTHER_CHANGES[@]}))
   if [ $total -eq 0 ]; then
       echo "No changes in this release."
   fi
} > "$RELEASE_NOTES_FILE"

{
  printf '%s\n' "# Changelog"
  echo ""
  printf '%s\n' "All releases and the changes included in them (pulled from git commits added since last release) will be detailed in this file."
  echo ""
} > "$CHANGELOG_FILE"


# Prepend the new release note in the changelog.md file
cat "$RELEASE_NOTES_FILE" "$CHANGELOG_FILE.tmp" >> "$CHANGELOG_FILE"

echo "Release notes generated: $CHANGELOG_FILE"
rm -fr $CHANGELOG_FILE.tmp

# git tag -a "$NEW_TAG" -m "Kubeaid Release $NEW_TAG"
# git push origin --tags
# git push github --tags
