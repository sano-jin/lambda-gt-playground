#!/bin/bash

set -eux

# Build backend
cd lambda_gt_alpha
./deploy.sh
cd ..

# Build frontend
PUBLIC_URL=./ elm-app build
rm -rf docs
cp -r build docs
