#!/bin/bash

branch=main
message="dummy commit" 
toCommit="."

if [ $# -ge 2 ]
  then
    branch=$1
    message=$2
    replace=" "
    toCommit=`echo $3 | sed -e "s/,/$replace/g"`
fi

git add ${toCommit:=.}
git commit -m $message
git push origin $branch 