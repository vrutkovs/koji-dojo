#!/bin/bash

DIR=$(dirname $(dirname $(realpath $0)))

set -x
docker build --tag=vrutkovs/koji-dojo-builder $DIR
