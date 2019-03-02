#!/usr/bin/env bash

# Wrapper script of release.sh for running on a CI.

set -xeu

root=`git rev-parse --show-toplevel`

cd $root


blackbox_postdeploy

chmod 400 _tools/deploy-key/github-deploy-key
ssh-keygen -F github.com > /dev/null || (mkdir -p ~/.ssh && echo "github.com,192.30.253.113 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> ~/.ssh/known_hosts)


if test "$1" == "ios" ; then
    eval $(ssh-agent -s)
    cat _tools/secrets/fastlane_match_certificates_id_rsa | ssh-add -

    cd ios && fastlane match appstore --readonly && cd ..
fi


GIT_SSH_COMMAND='ssh -i _tools/deploy-key/github-deploy-key' \
    GIT_PUSH_REMOTE='git@github.com:hpoul/finalyzer-game.git' \
    ./release.sh "$@"
