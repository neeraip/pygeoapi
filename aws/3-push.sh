#!/bin/sh

source $(dirname "$0")/init.sh

docker push $AWS_ECR_TAG
