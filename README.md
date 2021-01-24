# github-release-orb

[![CircleCI Build Status](https://circleci.com/gh/duffn/github-release-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/duffn/github-release-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/duffn/github-release)](https://circleci.com/orbs/registry/orb/duffn/github-release) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/duffn/github-release-orb/master/LICENSE)

A CircleCI orb to automatically create releases for a GitHub repository.

## Usage

- Add the orb to your CircleCI `config.yml`.
  - Find the latest version in [the CircleCI orb registry](https://circleci.com/developer/orbs/orb/duffn/github-release).

```yaml
version: 2.1

orbs:
  github-release: duffn/github-release@<version>

jobs:
  release:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - github-release/release

workflows:
  release:
    jobs:
      - release:
          filters:
            branches:
              only:
                - main
```

- Specify `[semver:<major|minor|patch>]` in your commit message to trigger a new release.
  - The org will extract the SemVer from your commit message and bump the GitHub version accordingly.
  - Add `[semver:skip]` to your commit message to skip publishing a release or just leave `[semver:<anything>]` out entirely.
- See the examples and documentation in [the CircleCI orb registry](https://circleci.com/developer/orbs/orb/duffn/github-release) for more.

## Setup

Usage of the orb requires some additional setup.

- The orb requires [`curl`](https://curl.se/). Ensure that your Docker image or executor has `curl` installed.
- You must set the `GITHUB_TOKEN` environment variable.
  - This environment variable must have [permissions to create releases in your repository](https://github.com/settings/tokens/new?description=CircleCI%20GitHub%20token&scopes=repo).
