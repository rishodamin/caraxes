
from flask import Blueprint, request, jsonify
import logging
import requests

from services.routing_service import calculate_route
from services.firestore_service import get_all_hazards


routing_bp = Blueprint(
    "routing",
    __name__
)


# --------------------------------
# Logging
# --------------------------------

logger = logging.getLogger(__name__)


# --------------------------------
# Validate coordinate
# --------------------------------

def validate_coordinate(
    value,
    field_name
):

    try:

        coordinate = float(value)

    except (TypeError, ValueError):

        raise ValueError(
            f"{field_name} must be a valid number"
        )

    if field_name.endswith("_lat"):

        if not -90 <= coordinate <= 90:

            raise ValueError(
                f"{field_name} must be between -90 and 90"
            )

    elif field_name.endswith("_lon"):

        if not -180 <= coordinate <= 180:

            raise ValueError(
                f"{field_name} must be between -180 and 180"
            )

    return coordinate


@routing_bp.route(
    "/route",
    methods=["POST"]
)
def route():

    # --------------------------------
    # 1. Check JSON body
    # --------------------------------

    if not request.is_json:

        return jsonify({
            "success": False,
            "error": "Content-Type must be application/json"
        }), 400


    data = request.get_json(
        silent=True
    )


    if not data or not isinstance(data, dict):

        return jsonify({
            "success": False,
            "error": "Valid JSON body is required"
        }), 400


    # --------------------------------
    # 2. Get start and destination
    # --------------------------------

    start = data.get(
        "start"
    )

    destination = data.get(
        "destination"
    )


    if start is None:

        return jsonify({
            "success": False,
            "error": "start is required"
        }), 400


    if destination is None:

        return jsonify({
            "success": False,
            "error": "destination is required"
        }), 400


    # Both must be JSON objects
    if not isinstance(start, dict):

        return jsonify({
            "success": False,
            "error": "start must be an object"
        }), 400


    if not isinstance(destination, dict):

        return jsonify({
            "success": False,
            "error": "destination must be an object"
        }), 400


    # --------------------------------
    # 3. Check required coordinates
    # --------------------------------

    required_start_fields = [
        "lat",
        "lon"
    ]

    required_destination_fields = [
        "lat",
        "lon"
    ]


    for field in required_start_fields:

        if field not in start:

            return jsonify({
                "success": False,
                "error": f"start.{field} is required"
            }), 400


    for field in required_destination_fields:

        if field not in destination:

            return jsonify({
                "success": False,
                "error": (
                    f"destination.{field} is required"
                )
            }), 400


    # --------------------------------
    # 4. Validate coordinates
    # --------------------------------

    try:

        start_lat = validate_coordinate(
            start["lat"],
            "start_lat"
        )

        start_lon = validate_coordinate(
            start["lon"],
            "start_lon"
        )

        destination_lat = validate_coordinate(
            destination["lat"],
            "destination_lat"
        )

        destination_lon = validate_coordinate(
            destination["lon"],
            "destination_lon"
        )

    except ValueError as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 400


    # --------------------------------
    # 5. Prevent identical points
    # --------------------------------

    if (
        start_lat == destination_lat
        and
        start_lon == destination_lon
    ):

        return jsonify({
            "success": False,
            "error": (
                "Start and destination "
                "cannot be the same"
            )
        }), 400


    # --------------------------------
    # 6. Get disaster locations
    # --------------------------------

    try:

        hazards = get_all_hazards()

    except Exception:

        logger.exception(
            "Failed to retrieve disaster locations"
        )

        return jsonify({
            "success": False,
            "error": (
                "Failed to retrieve "
                "disaster data"
            )
        }), 500


    # --------------------------------
    # 7. Calculate route
    # --------------------------------

    try:

        result = calculate_route(

            {
                "lat": start_lat,
                "lon": start_lon
            },

            {
                "lat": destination_lat,
                "lon": destination_lon
            },

            hazards
        )


    except requests.exceptions.Timeout:

        logger.exception(
            "Routing service timed out"
        )

        return jsonify({
            "success": False,
            "error": "Routing service timed out"
        }), 504


    except requests.exceptions.ConnectionError:

        logger.exception(
            "Unable to connect to routing service"
        )

        return jsonify({
            "success": False,
            "error": "Routing service unavailable"
        }), 502


    except requests.exceptions.RequestException:

        logger.exception(
            "Routing service request failed"
        )

        return jsonify({
            "success": False,
            "error": "Routing service request failed"
        }), 502


    except Exception:

        logger.exception(
            "Route calculation failed"
        )

        return jsonify({
            "success": False,
            "error": "Route calculation failed"
        }), 500


    # --------------------------------
    # 8. Validate route result
    # --------------------------------

    if not isinstance(result, dict):

        logger.error(
            "Invalid response from routing service"
        )

        return jsonify({
            "success": False,
            "error": "Invalid route result"
        }), 500


    if not result.get("route"):

        return jsonify({
            "success": False,
            "error": "No route found"
        }), 404


    # --------------------------------
    # 9. Return successful response
    # --------------------------------

    return jsonify({

        "success": True,

        **result

    }), 200

