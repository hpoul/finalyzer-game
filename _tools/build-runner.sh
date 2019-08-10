#!/usr/bin/env bash

set -xeu

dir="${0%/*}"
cd "$dir"/..

flutter packages pub run build_runner build --delete-conflicting-outputs

