# github-release-orb

[![CircleCI Build Status](https://circleci.com/gh/duffn/github-release-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/duffn/github-release-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/duffn/github-release)](https://circleci.com/orbs/registry/orb/duffn/github-release) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/duffn/github-release-orb/master/LICENSE)

A CircleCI orb to automatically create tags and releases for a GitHub repository.

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
      - add_ssh_keys:
          fingerprints:
            - "SO:ME:FIN:G:ER:PR:IN:T"
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

- Now, you will get a minor version bump, new tag, and GitHub release on every merge to `main`.
- See the examples and documentation in [the CircleCI orb registry](https://circleci.com/developer/orbs/orb/duffn/github-release) for more.

## Setup

Usage of the orb requires some additional setup.

- The orb requires [`curl`](https://curl.se/). Ensure that your Docker image or executor has `curl` installed.
- If you want the orb to create a GitHub release as well as push tags to GitHub, you must set the `GITHUB_TOKEN` environment variable.
  - This environment variable must have [permissions to create releases in your repository](https://github.com/settings/tokens/new?description=CircleCI%20GitHub%20token&scopes=repo).
- You must [add an SSH key to CircleCI and to your job steps](https://circleci.com/docs/2.0/add-ssh-key/#circleci-cloud) where you are using the orb and that key must have access to push tags to your repository.
