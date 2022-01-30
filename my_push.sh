#!/bin/bash

branch=main
message="dummy commit" 

if [ $# -ge 2 ]
  then
    branch=$1
    message=$2
fi

git add .
git commit -m $message
git push origin $branch 