#!/bin/bash

# import package signing key
gpg --import /tmp/agent-package-signing-key.txt
# clean existing build if any
cd /agent2/src/rackspace-monitoring-agent
make clean
# trigger agent build
cd /agent2
./build.sh
# to keep docker session connected
#/bin/bash "$@"
