#!/usr/bin/env bash

set -e
# debug log
set -xeu

DEPS=${DEPS} # must be defined by environment.

FLUTTER_VERSION=v1.2.1-stable
FLUTTER_PLATFORM=macos

platform="$(uname -s)"
case "${platform}" in
    Linux*)     FLUTTER_PLATFORM=linux;;
    Darwin*)    FLUTTER_PLATFORM=mac;;
    *)          echo "Unknown platform ${platform} exit 1 ;;
esac

pushd ${DEPS}
curl -o flutter.zip https://storage.googleapis.com/flutter_infra/releases/stable/${FLUTTER_PLATFORM}/flutter_${FLUTTER_PLATFORM}_${FLUTTER_VERSION}.zip

unzip ${DEPS}/flutter.zip | tail

popd

export PATH=${DEPS}/flutter/bin:$PATH

