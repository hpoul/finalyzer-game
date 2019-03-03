#!/usr/bin/env bash

set -exu

DEPS=${DEPS:-~/deps}

root=`git rev-parse --show-toplevel`

mkdir -p ${DEPS}
pushd ${DEPS}

git clone https://github.com/mipmip/blackbox

popd

cd ${root}

DEPS=${DEPS} _tools/install_flutter.sh

