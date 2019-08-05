#!/usr/bin/env bash

set -exu

DEPS=${DEPS:-~/deps}

root=`git rev-parse --show-toplevel`

echo "Installing blackbox into $DEPS" 
mkdir -p ${DEPS}
pushd ${DEPS}

git clone https://github.com/mipmip/blackbox

popd

echo "Installing flutter into $DEPS"

cd ${root}

DEPS=${DEPS} _tools/install_flutter.sh

