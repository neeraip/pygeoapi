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

ENV PYGEOAPI_CONFIG=/app/config.yml
ENV PYGEOAPI_OPENAPI=/app/openapi.yml

COPY entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]