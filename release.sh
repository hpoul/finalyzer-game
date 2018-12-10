#!/bin/bash

set -xe

case "$1" in
    ios)
        flutter build ios -t lib/env/production.dart
        cd ios
        fastlane beta
    ;;
    android)
        echo "case 2 or 3"
    ;;
    *)
        echo "Unsupported command $1"
    ;;
esac




