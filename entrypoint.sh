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

# Determine the URL based on environment
if [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
    echo "Running in ECS, getting container IP address..."
    CONTAINER_IP=$(curl -s "$ECS_CONTAINER_METADATA_URI_V4" | jq -r '.Networks[0].IPv4Addresses[0]')
    PYGEOAPI_URL="http://${CONTAINER_IP}:${PYGEOAPI_PORT}"
    echo "Using ECS container URL: $PYGEOAPI_URL"
else
    PYGEOAPI_URL="http://localhost:${PYGEOAPI_PORT}"
    echo "Using localhost URL: $PYGEOAPI_URL"
fi

echo "Invoking Lambda to generate pygeoapi configuration: $LAMBDA_PYGEOAPI_CONFIG_GENERATOR"
aws lambda invoke \
    --function-name $LAMBDA_PYGEOAPI_CONFIG_GENERATOR \
    --payload "{ \"options\": { \"host\": \"0.0.0.0\", \"port\": ${PYGEOAPI_PORT}, \"url\": \"${PYGEOAPI_URL}\" } }" \
    --cli-binary-format raw-in-base64-out \
    /app/response.json
jq -r '.body' /app/response.json > ${PYGEOAPI_CONFIG}
echo "Generated pygeoapi configuration at: $PYGEOAPI_CONFIG"

echo "Generating OpenAPI specification at: $PYGEOAPI_OPENAPI"
/venv/bin/pygeoapi openapi generate ${PYGEOAPI_CONFIG} --output-file ${PYGEOAPI_OPENAPI}

echo "Starting pygeoapi server with authentication..."
cd /app && /venv/bin/gunicorn --bind 0.0.0.0:${PYGEOAPI_PORT} custom_flask_app:APP