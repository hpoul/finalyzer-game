#!/bin/bash

set -xe

if test -d flutter/bin ; then
  echo "Adding flutter/bin to PATH"
  export PATH=$PATH:flutter/bin
fi

flutter --version

if ! test -e ./git-buildnumber.sh ; then
    curl -s -O https://raw.githubusercontent.com/hpoul/git-buildnumber/v1.0/git-buildnumber.sh
    chmod +x git-buildnumber.sh
fi


buildnumber=`./git-buildnumber.sh`

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




