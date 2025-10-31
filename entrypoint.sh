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

# Determine the URL - use configured domain first, then try public IP, fallback to localhost
if [ -n "$PYGEOAPI_DOMAIN" ]; then
    PYGEOAPI_URL="http://${PYGEOAPI_DOMAIN}:${PYGEOAPI_PORT}"
    echo "Using configured domain URL: $PYGEOAPI_URL"
else
    echo "No domain configured, getting public IP address..."
    PUBLIC_IP=$(curl -s --max-time 10 ipv4.icanhazip.com)
    
    if [ -n "$PUBLIC_IP" ]; then
        PYGEOAPI_URL="http://${PUBLIC_IP}:${PYGEOAPI_PORT}"
        echo "Using public IP URL: $PYGEOAPI_URL"
    else
        echo "Warning: Could not get public IP, using localhost"
        PYGEOAPI_URL="http://localhost:${PYGEOAPI_PORT}"
    fi
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