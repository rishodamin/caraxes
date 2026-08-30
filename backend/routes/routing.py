from flask import Blueprint, request, jsonify

from services.routing_service import calculate_route
from services.firestore_service import get_all_hazards


routing_bp = Blueprint(
    "routing",
    __name__
)


@routing_bp.route(
    "/route",
    methods=["POST"]
)
def route():

    data = request.get_json()

    if not data:
        return jsonify({
            "success": False,
            "error": "JSON body is required"
        }), 400

    start = data.get("start")
    destination = data.get("destination")

    if not start:
        return jsonify({
            "success": False,
            "error": "start is required"
        }), 400

    if not destination:
        return jsonify({
            "success": False,
            "error": "destination is required"
        }), 400

    try:

        start_lat = float(
            start["lat"]
        )

        start_lon = float(
            start["lon"]
        )

        destination_lat = float(
            destination["lat"]
        )

        destination_lon = float(
            destination["lon"]
        )

    except (
        KeyError,
        TypeError,
        ValueError
    ):

        return jsonify({
            "success": False,
            "error": "Invalid coordinates"
        }), 400

    try:

        # Get all disaster locations
        hazards = get_all_hazards()

        # Calculate safest available route
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

        return jsonify({
            "success": True,
            **result
        }), 200

    except Exception as e:

        return jsonify({
            "success": False,
            "error": "Route calculation failed",
            "details": str(e)
        }), 500