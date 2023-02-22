#!/bin/bash

exec gpg --import /tmp/agent-package-signing-key.txt
exec rm -f /tmp/agent-package-signing-key.txt
exec cd /agent2; ./build.sh
