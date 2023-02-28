#!/bin/bash

# import package signing key
gpg --import /tmp/agent-package-signing-key.txt

# clean existing build if any
BUILD_DIR="/agent2/src/rackspace-monitoring-agent"
if [ -d "$BUILD_DIR" ]; then
  cd /agent2/src/rackspace-monitoring-agent
  make clean
fi

# trigger agent build
cd /agent2
./build.sh

# to keep docker session connected
/bin/bash "$@"
