"""
Custom Flask app wrapper for pygeoapi with authentication
"""

import os
import logging
from pygeoapi.flask_app import APP as PYGEOAPI_APP
from custom_auth import init_auth

LOGGER = logging.getLogger(__name__)

# Initialize authentication on the pygeoapi Flask app
APP = init_auth(PYGEOAPI_APP)

if __name__ == "__main__":
    # For development/testing
    APP.run(host="0.0.0.0", port=int(os.getenv("PYGEOAPI_PORT", 5000)), debug=True)
