FROM python:3.13-slim

# Install minimal system deps and build tools needed by many Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl jq ca-certificates build-essential libpq-dev \
    gdal-bin libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip -d /app && \
    /app/aws/install && \
    rm -rf awscliv2.zip /app/aws

# Create an isolated virtual environment and ensure pip is up-to-date
RUN python3 -m venv /venv && /venv/bin/python3 -m pip install --upgrade pip
COPY requirements.txt /app/requirements.txt
RUN /venv/bin/python3 -m pip install --no-cache-dir -r /app/requirements.txt

# Replace the default parquet.py with custom version
COPY custom-parquet.py /venv/lib/python3.13/site-packages/pygeoapi/provider/parquet.py

# Copy custom authentication and Flask app
COPY custom-auth.py /app/custom_auth.py
COPY custom-flask-app.py /app/custom_flask_app.py

ENV PYGEOAPI_CONFIG=/app/config.yml
ENV PYGEOAPI_OPENAPI=/app/openapi.yml
ENV PYTHONPATH=/app:$PYTHONPATH

COPY entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]