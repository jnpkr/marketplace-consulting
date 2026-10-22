#!/usr/bin/env bash
# Propose sha bumps for the pinned third-party entries in marketplace.json.
#
# For each entry whose source sets `sha`, compare the pin with the current head
# of its `ref` upstream. When they differ, push a `bump/<plugin>` branch that
# moves the pin and open (or refresh) one pull request for that entry.
#
# Env:
#   GH_TOKEN     token for gh (the workflow passes GITHUB_TOKEN)
#   BASE_BRANCH  branch to compare against and open PRs into (default: current)
#   DRY_RUN=1    report what would change without pushing or opening PRs
set -euo pipefail

MARKETPLACE=.claude-plugin/marketplace.json
BASE=${BASE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
DRY_RUN=${DRY_RUN:-0}
MAX_FILES=50
failures=0

# Print the owner/repo of a github.com URL, or nothing for other hosts.
github_repo_of() {
  sed -nE 's#^(https://github\.com/|git@github\.com:)([^/]+/[^/]+)$#\2#p' <<<"${1%.git}"
}

# Print the commit a branch or tag currently points to, preferring a branch.
remote_head() {
  local url=$1 ref=$2 refs
  refs=$(git ls-remote "$url") || return 1
  if [[ $ref == HEAD ]]; then
    awk '$2 == "HEAD" { print $1; exit }' <<<"$refs"
    return
  fi
  for candidate in "refs/heads/$ref" "refs/tags/$ref^{}" "refs/tags/$ref"; do
    awk -v r="$candidate" '$2 == r { print $1; found = 1; exit } END { exit !found }' <<<"$refs" && return
  done
  return 1
}

# Write the pull request body for one bump to stdout.
pr_body() {
  local name=$1 type=$2 url=$3 gh_repo=$4 ref=$5 path=$6 old=$7 new=$8
  echo "Moves the \`$name\` pin on \`$ref\` from \`${old:0:12}\` to \`${new:0:12}\`."
  echo
  if [[ -z $gh_repo ]]; then
    echo "Upstream: $url (not on github.com, so there is no compare link). Review the commits between the two shas before merging."
    return
  fi
  echo "Review the upstream changes: https://github.com/$gh_repo/compare/$old...$new"

  local compare status ahead files total
  if ! compare=$(gh api "repos/$gh_repo/compare/$old...$new" 2>/dev/null); then
    echo
    echo "The compare API call failed, so this body has no file summary. Use the link above."
    return
  fi
  status=$(jq -r .status <<<"$compare")
  ahead=$(jq -r .ahead_by <<<"$compare")
  echo
  echo "Upstream is $ahead commit(s) ahead of the current pin."
  if [[ $status != ahead ]]; then
    echo
    echo "**Warning:** the compare status is \`$status\`, so the new head doesn't simply follow the old pin. Upstream history may have been rewritten."
  fi

  if [[ $type == git-subdir ]]; then
    files=$(jq -r --arg p "${path%/}/" '.files[]?.filename | select(startswith($p))' <<<"$compare")
    total=$(jq '.files | length' <<<"$compare")
    echo
    if [[ -z $files ]]; then
      echo "**No files under \`$path\` changed.** Only that folder is installed, so this bump changes nothing for users."
    else
      echo "**Files changed under \`$path\`:**"
      echo
      head -n "$MAX_FILES" <<<"$files" | sed 's/^/- `/; s/$/`/'
      if (( $(wc -l <<<"$files") > MAX_FILES )); then
        echo "- …and more"
      fi
    fi
    if (( total >= 300 )); then
      echo
      echo "The compare API lists at most 300 files, so this summary may be incomplete."
    fi
  fi
}

git fetch --quiet origin "$BASE"

while IFS= read -r entry; do
  index=$(jq -r .index <<<"$entry")
  name=$(jq -r .name <<<"$entry")
  type=$(jq -r .source.source <<<"$entry")
  old=$(jq -r .source.sha <<<"$entry")
  ref=$(jq -r '.source.ref // "HEAD"' <<<"$entry")
  path=$(jq -r '.source.path // ""' <<<"$entry")

  case $type in
    github) url="https://github.com/$(jq -r .source.repo <<<"$entry").git" ;;
    git-subdir | url)
      url=$(jq -r .source.url <<<"$entry")
      # git-subdir accepts GitHub owner/repo shorthand.
      [[ $url =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] && url="https://github.com/$url.git"
      ;;
    *) echo "::warning::$name: unsupported source type $type"; continue ;;
  esac
  gh_repo=$(github_repo_of "$url")

  if ! new=$(remote_head "$url" "$ref"); then
    echo "::error::$name: could not read $ref from $url"
    failures=$((failures + 1))
    continue
  fi
  if [[ $new == "$old" ]]; then
    echo "$name: up to date at ${old:0:12}"
    continue
  fi
  echo "$name: $ref moved from ${old:0:12} to ${new:0:12}"

  branch="bump/$name"
  body=$(pr_body "$name" "$type" "$url" "$gh_repo" "$ref" "$path" "$old" "$new")
  if [[ $DRY_RUN == 1 ]]; then
    printf '%s\n\n' "$body"
    continue
  fi

  # Leave an open PR alone if its branch already proposes this commit.
  pr=$(gh pr list --head "$branch" --base "$BASE" --state open --json number --jq '.[0].number // empty')
  if [[ -n $pr ]] && git fetch --quiet origin "$branch" 2>/dev/null &&
    [[ $(git show "FETCH_HEAD:$MARKETPLACE" | jq -r ".plugins[$index].source.sha") == "$new" ]]; then
    echo "$name: PR #$pr already proposes ${new:0:12}"
    continue
  fi

  git checkout --quiet -B "$branch" "origin/$BASE"
  jq --indent 2 --argjson i "$index" --arg sha "$new" '.plugins[$i].source.sha = $sha' "$MARKETPLACE" >"$MARKETPLACE.tmp"
  mv "$MARKETPLACE.tmp" "$MARKETPLACE"
  git commit --quiet -am "chore: bump $name to ${new:0:12}"
  git push --quiet --force origin "$branch"
  git checkout --quiet "origin/$BASE"

  title="Bump $name to ${new:0:12}"
  if [[ -n $pr ]]; then
    gh pr edit "$pr" --title "$title" --body "$body" >/dev/null
    echo "$name: updated PR #$pr"
  else
    gh pr create --base "$BASE" --head "$branch" --title "$title" --body "$body"
  fi
done < <(jq -c '.plugins | to_entries[] | select((.value.source | type) == "object" and (.value.source.sha // "") != "") | {index: .key, name: .value.name, source: .value.source}' "$MARKETPLACE")

exit $((failures > 0))
