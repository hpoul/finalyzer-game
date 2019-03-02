#!/bin/bash

set -e
# debug log
set -x

FLUTTER_VERSION=v1.2.1-stable

curl -o flutter.zip https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}.zip

unzip flutter.zip | tail

export PATH=flutter/bin:$PATH



