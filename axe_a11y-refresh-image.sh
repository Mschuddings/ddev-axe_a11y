#!/usr/bin/env bash
#ddev-generated
#
# Keeps the axe_a11y scanner image current without paying for it on every start.
#
# The add-on used to set pull_policy: always on the :latest tag, which meant
# every ddev start contacted the registry and offline work was impossible. This
# script pulls at most once per MAX_AGE_SECONDS per machine instead, and runs as
# a pre-start hook so a newly pulled image is used by the start that triggered
# it. The stamp lives in the user's home directory, not in the project, so a
# machine with twenty DDEV projects still pulls once a day rather than per
# project.

set -eu

IMAGE="registry.gitlab.com/mschudders/accessibility_checker:latest"
MAX_AGE_SECONDS="${AXE_A11Y_MAX_IMAGE_AGE:-86400}"
# After a failed pull, retry sooner than a full day, but not on every start.
RETRY_AFTER_SECONDS="${AXE_A11Y_RETRY_AFTER:-3600}"
PULL_TIMEOUT_SECONDS="${AXE_A11Y_PULL_TIMEOUT:-60}"
STAMP="${HOME}/.ddev/.axe_a11y-last-pull"

# The epoch is stored as the file's contents rather than read from its mtime,
# because stat's flags differ between GNU and BSD and this has to work on Linux,
# macOS and WSL alike.
read_stamp() {
  local value
  value="$(cat "${STAMP}" 2>/dev/null || true)"
  case "${value}" in
    '' | *[!0-9]*) echo 0 ;;
    *) echo "${value}" ;;
  esac
}

write_stamp() {
  mkdir -p "$(dirname "${STAMP}")"
  echo "$1" > "${STAMP}"
}

have_image() {
  docker image inspect "${IMAGE}" >/dev/null 2>&1
}

image_id() {
  docker image inspect --format '{{.Id}}' "${IMAGE}" 2>/dev/null || echo none
}

pull_image() {
  # Bounded, so a start while offline does not sit waiting on Docker's own
  # retries. timeout is absent on a stock macOS, hence the fallback.
  if command -v timeout >/dev/null 2>&1; then
    timeout "${PULL_TIMEOUT_SECONDS}" docker pull --quiet "${IMAGE}" >/dev/null 2>&1
  else
    docker pull --quiet "${IMAGE}" >/dev/null 2>&1
  fi
}

now="$(date +%s)"

# A missing image has to be fetched regardless of when the last check was.
if have_image && [ "$(( now - $(read_stamp) ))" -lt "${MAX_AGE_SECONDS}" ]; then
  exit 0
fi

before="$(image_id)"

if ! pull_image; then
  write_stamp "$(( now - MAX_AGE_SECONDS + RETRY_AFTER_SECONDS ))"
  if have_image; then
    echo "axe_a11y: registry unreachable, keeping the scanner image already present." >&2
    exit 0
  fi
  echo "axe_a11y: could not pull ${IMAGE} and no local copy exists; 'ddev axe_a11y' will not work." >&2
  exit 0
fi

write_stamp "${now}"

if [ "${before}" != "$(image_id)" ]; then
  echo "axe_a11y: scanner image updated."
fi
