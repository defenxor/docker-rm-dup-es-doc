#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $dir

tag=$(git describe --tags 2>/dev/null)
app=$(basename $(pwd))
sudo docker build -t defenxor/${app}:latest .
[ "$tag" != "" ] && sudo docker tag defenxor/${app}:latest defenxor/${app}:$tag
