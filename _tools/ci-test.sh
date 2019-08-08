#!/usr/bin/env bash

set -xeu

DEPS=${DEPS:-~/deps}

root=$(git rev-parse --show-toplevel)

cd "${root}"
${DEPS}/blackbox/bin/blackbox_postdeploy
# Flutter was installed by `install_flutter.sh` in `ci-install-deps.sh`.
export PATH=${DEPS}/flutter/bin:$PATH

if test "$1" = "coverage"; then
  fail=false
  flutter test --coverage || fail=true
  echo "fail=$fail"

  source _tools/secrets/secrets.env && export CODECOV_TOKEN && bash <(curl -s https://codecov.io/bash) -f coverage/lcov.info
else
  flutter test
fi
