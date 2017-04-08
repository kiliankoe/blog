#!/bin/bash

echo -e "\033[0;32mBuilding current version\033[0m"

hugo

git add docs/*

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -S -m "$msg"

echo -e "\033[0;32mPushing to GitHub\033[0m"

git push origin master

echo -e "\033[0;32mAll done 👌\033[0m"
