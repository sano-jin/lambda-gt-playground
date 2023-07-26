#!/bin/bash

set -eux

rootdir="$PWD"

# Build backend
cd lambda_gt_alpha

dune build
dune build js
cp _build/default/js/js.bc.js "$rootdir/docs/runtime.js"

cd "$rootdir"

# Build frontend
PUBLIC_URL=./ elm-app build
rm -rf docs
cp -r build docs
