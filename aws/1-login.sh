#!/bin/sh

source $(dirname "$0")/init.sh

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 087383746182.dkr.ecr.us-east-2.amazonaws.com
