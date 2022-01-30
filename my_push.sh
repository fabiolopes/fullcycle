#!/bin/bash

branch=main
message="dummy commit"
echo "arguments: $1,$2" 

if [ $# -ge 2 ]
  then
    branch=$1
    message=$2
    echo "Variaveis atribuídas: $branch, $message"
fi

git add .
git commit -m $message
git push origin $branch 