#!/bin/bash

set -xe

case "$1" in
    ios)
        flutter build ios -t lib/env/production.dart --release
        cd ios
        fastlane beta
    ;;
    android)
        flutter build apk -t lib/env/production.dart --release
        cd android
        fastlane beta
    ;;
    *)
        echo "Unsupported command $1"
    ;;
esac




