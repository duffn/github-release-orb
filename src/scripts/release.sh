main() {
  local last_tag
  local new_tag

  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"

  if [ -z "$(git tag)" ]; then
    last_tag="0.0.0"
  else
    last_tag=$(git describe --tags --abbrev=0)
  fi
  new_tag=$(semver bump "$semver_increment" "$last_tag")

  tag_commit "$new_tag"
}

tag_commit() {
  local new_tag
  new_tag="$1"

  echo "Creating tag $new_tag."

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
    -S -s -o /dev/null \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$json" \
    "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases"
  
  echo "Release $new_tag created."
}

get_semver_increment() {
  local commit_subject
  commit_subject=$(git log -1 --pretty=%s.)
  semver_increment=$(echo "$commit_subject" | sed -En 's/.*\[semver:(major|minor|patch|skip)\].*/\1/p')

  echo "Commit subject: $commit_subject"
  echo "SemVer increment: $semver_increment"
}

check_increment() {
  local response
  response="yes"

  echo "Semver increment in check: $semver_increment"
  if [ -z "$semver_increment" ]; then
    echo "Commit subject did not indicate which SemVer increment to make."
    echo "To create the tag and release, you can ammend the commit or push another commit with [semver:INCREMENT] in the subject where INCREMENT is major, minor, patch."
    echo "Note: To indicate intention to skip, include [semver:skip] in the commit subject instead."
    response="no"
  elif [ "$semver_increment" == "skip" ]; then
    echo "SemVer in commit indicated to skip release."
    response="no"
  fi
  echo "$response"
}

check_for_envs() {
  if [ "$RELEASE" == "1" ] && [ -z "$GITHUB_TOKEN" ]; then
    echo "The GITHUB_TOKEN environment variable is not set."
    echo "With the release parameter set to true, you must set a GITHUB_TOKEN environment variable."
    exit 1
  fi

  if [ "$(id -u)" == 0 ]; then 
    export SUDO=""
  else 
    export SUDO="sudo"
  fi
}

check_for_programs() {
  if ! command -v curl &> /dev/null; then
    echo "You must have curl installed to use this orb."
    exit 1
  fi
}

download_programs() {
  if ! command -v semver &> /dev/null; then
    semver_version="3.2.0"
    echo "Installing semver version $semver_version"
    wget -qO- "https://github.com/fsaintjacques/semver-tool/archive/$semver_version.tar.gz" | tar xzf -
    chmod +x "semver-tool-$semver_version/src/semver"
    "$SUDO" cp "semver-tool-$semver_version/src/semver" /usr/local/bin
  fi

  if ! command -v jq &> /dev/null; then
    jq_version="1.6"
    echo "Installing jq version $jq_version"
    wget -qO jq "https://github.com/stedolan/jq/releases/download/jq-$jq_version/jq-linux$arch"
    chmod +x jq
    "$SUDO" cp jq /usr/local/bin
  fi
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  get_semver_increment
  increment=$(check_increment)
  if [ "$increment" == "yes" ]; then
    check_for_envs
    check_for_programs
    download_programs
    main
  fi
fi
