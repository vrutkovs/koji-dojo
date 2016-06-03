#!/bin/bash

DIR=$(dirname $(dirname $(realpath $0)))

docker build --tag=vrutkovs/koji-dojo-client $DIR
