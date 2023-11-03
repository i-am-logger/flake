#!/usr/bin/env bash

# Checko for the correct number of arguments
if [ $# -ne 1]; then
  echo "Usage: $0 <old_commit_hash>"
  exit 1
fi

old_commit_hash = "$1"

git checkout "$old_commit_hash"
git branch temp
git checkout temp
git branch -f master temp
git checkout master
git branch -d temp
