#!/usr/bin/env bash

set -exu

root=`git rev-parse --show-toplevel`

cd $root

git clone https://github.com/mipmip/blackbox && cd blackbox && make manual-install && cd ..


_tools/install_flutter.sh

