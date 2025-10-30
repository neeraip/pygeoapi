#!/bin/sh

$(dirname "$0")/1-login.sh
$(dirname "$0")/2-build.sh
$(dirname "$0")/3-push.sh
