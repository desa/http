#!/usr/bin/env bash

set -o errexit
set -o nounset

verify_args() {
  echo "Cutting a release for version $version with commit $commit"
  while true; do
    read -rp "Is this correct (y/n)?" yn
    case $yn in
    [Yy]*) break;;
    [Nn]*) exit;;
    *) echo "Please answer y or n.";;
    esac
  done
}

update_version() {
  echo "$version" > VERSION
  echo "VERSION set to $version"
}

if [ $# -le 2 ]; then
  echo "version and commit arguments required"
fi

set -eu
version=$1
commit=$2

verify_args

# create version release branch
git checkout master
git pull
if ! git diff --exit-code master origin/master
then
  echo "ERROR! There are local-only changes on branch 'master'!"
  exit 1
fi
git checkout -b "release-$version" "$commit"

# update VERSION
update_version

# commit VERSION and CHANGELOG updates
git add VERSION
git commit -m "Prep for $version release

[skip ci]"

# merge into release
git checkout release
if ! git diff --exit-code release origin/release
then
  echo "ERROR! There are local-only changes on branch 'release'!"
  exit 1
fi
git merge "release-$version" -m "Release $version"

# tag release
git tag "$version"

# push to release branch
git push origin release
git push origin "$version"

git checkout master
git merge "release-$version"

git push origin master
