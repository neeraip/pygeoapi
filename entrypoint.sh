#!/bin/sh

if [ -z "$LAMBDA_PYGEOAPI_CONFIG_GENERATOR" ]; then
    echo "LAMBDA_PYGEOAPI_CONFIG_GENERATOR environment variable is not set."
    exit 1
fi

if [ -z "$PYGEOAPI_PORT" ]; then
    echo "PYGEOAPI_PORT environment variable is not set. Using default port 5000."
    PYGEOAPI_PORT=5000
fi

if [ -z "$PYGEOAPI_CONFIG" ]; then
    echo "PYGEOAPI_CONFIG environment variable is not set."
    exit 1
fi

if [ -z "$PYGEOAPI_OPENAPI" ]; then
    echo "PYGEOAPI_OPENAPI environment variable is not set."
    exit 1
fi

echo "Invoking Lambda to generate pygeoapi configuration: $LAMBDA_PYGEOAPI_CONFIG_GENERATOR"
aws lambda invoke \
    --function-name $LAMBDA_PYGEOAPI_CONFIG_GENERATOR \
    --payload "{ \"options\": { \"port\": ${PYGEOAPI_PORT} } }" \
    --cli-binary-format raw-in-base64-out \
    /app/response.json
jq -r '.body' /app/response.json > ${PYGEOAPI_CONFIG}

echo "Generating OpenAPI specification at: $PYGEOAPI_OPENAPI"
/venv/bin/pygeoapi openapi generate ${PYGEOAPI_CONFIG} --output-file ${PYGEOAPI_OPENAPI}

echo "Starting pygeoapi server..."
/venv/bin/gunicorn --bind 0.0.0.0:${PYGEOAPI_PORT} pygeoapi.flask_app:APP