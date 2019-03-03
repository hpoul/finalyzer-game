#!/usr/bin/env bash

set -exu

DEPS=${DEPS:-~/deps}

mkdir -p ${DEPS} && cd ${DEPS}

git clone https://github.com/mipmip/blackbox

root=`git rev-parse --show-toplevel`
cd ${root}

_tools/install_flutter.sh

