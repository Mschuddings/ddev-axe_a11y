#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=Mschuddings/ddev-axe_a11y

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  # A DDEV project name has to be a valid hostname, and this repository's name
  # contains an underscore, which is not allowed in one. Deriving PROJNAME
  # verbatim made ddev config fail in setup with "is not a valid project name",
  # so every run failed before reaching a single assertion.
  export PROJNAME="test-$(basename "${GITHUB_REPO}" | tr '_' '-')"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # Scans the project's own site rather than an external one: it needs no
  # outbound network, and it exercises the ddev-router link and the mkcert
  # certificate, which is not trusted inside the scanner container.
  run ddev axe_a11y --no-open "https://${PROJNAME}.ddev.site"
  assert_success
  assert_output --partial "Report: "

  # A report is only useful if it reached the host, in both formats.
  run bash -c "ls ${TESTDIR}/reports/axe_a11y/results/report-*.html"
  assert_success
  run bash -c "ls ${TESTDIR}/reports/axe_a11y/results/report-*.json"
  assert_success

  # The report has to be a complete document, not a truncated one.
  run bash -c "grep -l '</html>' ${TESTDIR}/reports/axe_a11y/results/report-*.html"
  assert_success

  # Written as the host user, not as root: that is what running the container
  # with user: $DDEV_UID:$DDEV_GID is for.
  run bash -c "find ${TESTDIR}/reports/axe_a11y/results -name 'report-*.html' -user $(id -u) | wc -l"
  assert_success
  refute_output "0"

  # Called with no arguments it must explain itself and fail, not open the
  # results directory.
  run ddev axe_a11y
  assert_failure
  assert_output --partial "Usage:"

  # The hook that keeps the scanner image current must be installed and runnable.
  assert_file_executable "${TESTDIR}/.ddev/axe_a11y-refresh-image.sh"
  run grep -q "pre-start" "${TESTDIR}/.ddev/config.axe_a11y.yaml"
  assert_success
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
