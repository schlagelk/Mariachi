#!/bin/sh

if test -z "$INPUT_GITHUB_TOKEN"; then
  echo "Please set the github_token variable."
  exit 1
fi

if test -z "$INPUT_TEAMS_URL"; then
  echo "Please set the teams_url variable."
  exit 1
fi

if test -z "$GITHUB_REPOSITORY"; then
  echo "Please set a github_repository variable."
  exit 1
fi

if test -z "$INPUT_MIN_REVIEWS"; then
  INPUT_MIN_REVIEWS=2
fi

/bin/mariachi "${INPUT_GITHUB_TOKEN}" "${INPUT_TEAMS_URL}" "${GITHUB_REPOSITORY}" "${INPUT_EXCLUDE_HEADS}" "${INPUT_EXCLUDE_LABELS}" "${INPUT_MIN_REVIEWS}"
