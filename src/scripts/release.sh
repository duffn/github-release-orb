#!/bin/bash

if [ -z "$ORGANIZATION" ]; then
  echo "You must provide the organization parameter to this command."
  exit 1
fi

if [ -n "$RELEASE" ] && [ -z "$GITHUB_TOKEN" ]; then
  echo "With the release parameter set to true, you must set a GITHUB_TOKEN environment variable."
  exit 1
fi

main() {
  local last_tag
  local new_tag

  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"

  # TODO: We're assuming here that the tag is X.X.X semver and that we already have a tag.
  last_tag=$(git describe --tags --abbrev=0)
  IFS='.' read -ra version <<< "$last_tag"
  # shellcheck disable=SC2004
  # TODO: Allow major, minor, patch bumps.
  new_tag="${version[0]}.$((${version[1]} + 1)).0"

  tag_commit "$new_tag"
}

# Commit changes after version bump and push the new tag.
tag_commit() {
  local new_tag
  new_tag="$1"

  git add .
  git commit -m "Release ${new_tag} [skip ci]"
  git tag "$new_tag"
  git push
  git push --tags

  if [ "$RELEASE" = true ]; then
    release_github "$new_tag"
  fi
}

release_github() {
  local new_tag
  new_tag="$1"
  local json

  release_changelog=""
  if [ "$CHANGELOG" = true ]; then
    release_changelog=$(git log --pretty=format:'* %s (%h)' "$last_tag"..HEAD)
  fi

  # We need jq for the below.
  if [ "$(uname -m)" = "x86_64" ]; then
    arch="64"
  else
    arch="32"
  fi

  wget -qO jq https://github.com/stedolan/jq/releases/download/jq-"$JQ_VERSION"/jq-linux"$arch"
  chmod +x jq
  sudo mv jq /usr/local/bin

  json=$(jq -n \
    --arg tag_name "$new_tag" \
    --arg target_commitish "$CIRCLE_BRANCH" \
    --arg name "Release $new_tag" \
    --arg body "$release_changelog" \
    '{
      tag_name: $tag_name,
      target_commitish: $target_commitish,
      name: $name,
      body: $body,
      draft: false,
      prerelease: false
    }'
  )

  curl \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$json" \
    "https://api.github.com/repos/$ORGANIZATION/$CIRCLE_PROJECT_REPONAME/releases"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi
