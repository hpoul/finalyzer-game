#!/bin/bash

set -xe

if test -d flutter/bin ; then
  echo "Adding flutter/bin to PATH"
  export PATH=$PATH:flutter/bin
fi

flutter doctor

buildnumber=`git-buildnumber.sh`

case "$1" in
    ios)
        flutter build -v ios -t lib/env/production.dart --release --build-number $buildnumber
        cd ios
        fastlane beta
    ;;
    android)
        flutter build apk -t lib/env/production.dart --release --build-number $buildnumber
        cd android
        fastlane beta
    ;;
    *)
        echo "Unsupported command $1"
    ;;
esac




