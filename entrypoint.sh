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
    echo "Running in ECS, getting public IP address..."
    # Try to get public IP using AWS metadata service (works if task has public IP)
    PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "404" ]; then
        PYGEOAPI_URL="http://${PUBLIC_IP}:${PYGEOAPI_PORT}"
        echo "Using ECS public IP URL: $PYGEOAPI_URL"
    else
        echo "Could not get public IP, falling back to configured domain..."
        # Fallback to a configured domain or load balancer URL
        if [ -n "$PYGEOAPI_DOMAIN" ]; then
            PYGEOAPI_URL="http://${PYGEOAPI_DOMAIN}:${PYGEOAPI_PORT}"
            echo "Using configured domain URL: $PYGEOAPI_URL"
        else
            echo "Warning: No public IP or domain configured, using localhost"
            PYGEOAPI_URL="http://localhost:${PYGEOAPI_PORT}"
        fi
    fi
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