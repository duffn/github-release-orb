if [ "$RELEASE" == "1" ] && [ -z "$GITHUB_TOKEN" ]; then
  echo "With the release parameter set to true, you must set a GITHUB_TOKEN environment variable."
  exit 1
fi

main() {
  local last_tag
  local new_tag

  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"

  semver_version="3.2.0"
  wget -qO- "https://github.com/fsaintjacques/semver-tool/archive/$semver_version.tar.gz" | tar xzvf -
  chmod +x "semver-tool-$semver_version/src/semver"
  sudo cp "semver-tool-$semver_version/src/semver" /usr/local/bin

  if [ -z "$(git tag)" ]; then
    # We'll call the first tag 0.1.0 somewhat arbitrarily.
    echo "You do not yet have a tag in this repository. Creating 0.1.0 as the first tag."
    last_tag="0.1.0"
  else
    last_tag=$(git describe --tags --abbrev=0)
  fi
  new_tag=$(semver bump "$BUMP" "$last_tag")

  tag_commit "$new_tag"
}

# Commit changes after version bump and push the new tag.
tag_commit() {
  local new_tag
  new_tag="$1"

  git tag "$new_tag"
  git push --tags

  if [ "$RELEASE" == "1" ]; then
    release_github "$new_tag"
  fi
}

release_github() {
  local new_tag
  new_tag="$1"
  local json

  release_changelog=""
  if [ "$CHANGELOG" == "1" ]; then
    release_changelog=$(git log --pretty=format:'* %s (%h)' "$last_tag"..HEAD)
  fi

  # We need jq for the below.
  if [ "$(uname -m)" = "x86_64" ]; then
    arch="64"
  else
    arch="32"
  fi

  jq_version="1.6"
  wget -qO jq "https://github.com/stedolan/jq/releases/download/jq-$jq_version/jq-linux$arch"
  chmod +x jq
  sudo cp jq /usr/local/bin

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
    "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  main
fi
