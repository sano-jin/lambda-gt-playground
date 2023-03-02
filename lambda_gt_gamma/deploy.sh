#!/bin/bash

dune build
dune build js
cat _build/default/js/js.bc.js >../docs/runtime.js
