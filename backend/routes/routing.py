from flask import Blueprint, request, jsonify

from services.routing_service import calculate_route


routing_bp = Blueprint(
    "routing",
    __name__
)


@routing_bp.route("/route", methods=["POST"])
def route():

    data = request.get_json()

    if not data:
        return jsonify({
            "success": False,
            "error": "JSON body is required"
        }), 400

    # -------------------------
    # Validate start
    # -------------------------

    start = data.get("start")

    if not start:
        return jsonify({
            "success": False,
            "error": "Start location is required"
        }), 400

    if "lat" not in start or "lon" not in start:
        return jsonify({
            "success": False,
            "error": "Start must contain lat and lon"
        }), 400

    # -------------------------
    # Validate destination
    # -------------------------

    destination = data.get("destination")

    if not destination:
        return jsonify({
            "success": False,
            "error": "Destination is required"
        }), 400

    if "lat" not in destination or "lon" not in destination:
        return jsonify({
            "success": False,
            "error": "Destination must contain lat and lon"
        }), 400

    # -------------------------
    # Hazards
    # -------------------------

    hazards = data.get(
        "hazards",
        []
    )

    # -------------------------
    # Calculate route
    # -------------------------

    try:

        result = calculate_route(
            start=start,
            destination=destination,
            hazards=hazards
        )

    except Exception as e:

        return jsonify({
            "success": False,
            "error": "Route calculation failed",
            "details": str(e)
        }), 500

    return jsonify({
        "success": True,
        **result
    }), 200