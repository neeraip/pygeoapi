#!/bin/sh

source $(dirname "$0")/init.sh

cd $PYGEOAPI_PATH
docker compose build
