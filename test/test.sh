#!/bin/bash

# CWD is /test directory

moddir='/tmp/mods'

# clean workspace
#rm -rf   "${moddir}"
mkdir -p "${moddir}"

# install dependencies
jq -r .dependencies[].name < ../metadata.json | while read dep; do
  puppet module install --target-dir="${moddir}" "${dep}"
done

# install our module
rm -rf   "${moddir}/ipset"
mkdir    "${moddir}/ipset"
cp -r .. "${moddir}/ipset"

# run all test*.pp
find . -type f -name 'test*.pp' -print | while read item; do
  puppet apply --modulepath="${moddir}" --verbose --debug ${item}
done
