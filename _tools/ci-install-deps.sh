#!/usr/bin/env bash

set -ex

root=`git rev-parse --show-toplevel`

cd $root

git clone https://github.com/mipmip/blackbox && cd blackbox && make manual-install && cd ..

blackbox_postdeploy

_tools/install_flutter.sh

cd ios && fastlane match appstore --readonly && cd ..
