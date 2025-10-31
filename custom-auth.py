"""
Custom authentication middleware for pygeoapi
"""

import base64
import os
from functools import wraps
from flask import request, Response, current_app
import logging

LOGGER = logging.getLogger(__name__)


class AuthenticationError(Exception):
    pass


def check_auth(username, password):
    """
    Check if username/password combination is valid
    """
    # Get credentials from environment variables
    valid_username = os.getenv("PYGEOAPI_AUTH_USERNAME")
    valid_password = os.getenv("PYGEOAPI_AUTH_PASSWORD")

    if not valid_username or not valid_password:
        LOGGER.warning("Authentication credentials not configured")
        return False

    return username == valid_username and password == valid_password


def authenticate():
    """
    Send a 401 response that enables basic auth
    """
    return Response(
        "Authentication required\n" "You have to login with proper credentials",
        401,
        {"WWW-Authenticate": 'Basic realm="PyGeoAPI"'},
    )


def requires_auth(f):
    """
    Decorator that requires HTTP Basic Authentication
    """

    @wraps(f)
    def decorated(*args, **kwargs):
        # Skip auth for health check endpoints if needed
        if request.endpoint in ["health", "openapi"]:
            return f(*args, **kwargs)

        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)

    return decorated


def init_auth(app):
    """
    Initialize authentication for the Flask app
    """
    # Check if authentication is enabled
    auth_enabled = os.getenv("PYGEOAPI_AUTH_ENABLED", "false").lower() == "true"

    if not auth_enabled:
        LOGGER.info("Authentication disabled")
        return app

    LOGGER.info("Authentication enabled")

    # Apply authentication to all routes
    @app.before_request
    def require_authentication():
        # Skip auth for certain endpoints if needed
        if request.endpoint in ["health", "openapi", "landing_page"]:
            return None

        auth = request.authorization
        if not auth:
            return authenticate()

        if not check_auth(auth.username, auth.password):
            return authenticate()

    return app
