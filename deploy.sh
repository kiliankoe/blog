#!/bin/bash

echo -e "\033[0;32mDeploying current version to gh-pages...\033[0m"

hugo

git add public/*

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -S -m "$msg"

git push origin master
git subtree push --prefix=public git@github.com:kiliankoe/blog.git gh-pages
