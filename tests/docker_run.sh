#!/bin/bash

set -e

docker run --rm -v "${PWD}:/src" \
    -t "${1}" \
    bash /src/tests/run.sh
