#!/bin/bash
REVIEWDOG_VERSION="0.9.11"
curl -fSL https://github.com/haya14busa/reviewdog/releases/download/$REVIEWDOG_VERSION/reviewdog_linux_amd64 -o ~/bin/reviewdog
chmod +x ~/bin/reviewdog
