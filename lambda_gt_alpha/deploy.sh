#!/bin/bash

set -eux

dune build
dune build js
cp _build/default/js/js.bc.js ../docs/runtime.js
