"""
Token-based authentication middleware for pygeoapi
"""

import os
from functools import wraps
from flask import request, Response, jsonify
import logging

LOGGER = logging.getLogger(__name__)


def check_token(token):
    """
    Check if the provided token is valid
    """
    valid_token = os.getenv("PYGEOAPI_AUTH_TOKEN")
    if not valid_token:
        LOGGER.warning("Authentication token not configured")
        return False
    return token == valid_token


def token_required(f):
    """
    Decorator that requires a valid API token
    """

    @wraps(f)
    def decorated(*args, **kwargs):
        # Skip auth for health check endpoints if needed
        if request.endpoint in ["health", "openapi", "landing_page"]:
            return f(*args, **kwargs)

        token = None

        # Check for token in headers
        if "Authorization" in request.headers:
            auth_header = request.headers["Authorization"]
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                pass

        # Check for token in query parameters
        if not token:
            token = request.args.get("token")

        if not token:
            return jsonify({"error": "Token is missing"}), 401

        if not check_token(token):
            return jsonify({"error": "Invalid token"}), 401

        return f(*args, **kwargs)

    return decorated


def init_token_auth(app):
    """
    Initialize token authentication for the Flask app
    """
    auth_enabled = os.getenv("PYGEOAPI_AUTH_ENABLED", "false").lower() == "true"

    if not auth_enabled:
        LOGGER.info("Authentication disabled")
        return app

    LOGGER.info("Token authentication enabled")

    @app.before_request
    def require_token():
        # Skip auth for certain endpoints
        if request.endpoint in ["health", "openapi", "landing_page"]:
            return None

        token = None

        # Check for token in headers (Bearer token)
        if "Authorization" in request.headers:
            auth_header = request.headers["Authorization"]
            try:
                if auth_header.startswith("Bearer "):
                    token = auth_header.split(" ")[1]
            except IndexError:
                pass

        # Check for token in query parameters
        if not token:
            token = request.args.get("token")

        if not token:
            return jsonify({"error": "Authentication token required"}), 401

        if not check_token(token):
            return jsonify({"error": "Invalid authentication token"}), 401

    return app
