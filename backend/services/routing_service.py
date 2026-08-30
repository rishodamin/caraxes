
import math
import logging
import requests


# ---------------------------------------------
# Logging
# ---------------------------------------------

logger = logging.getLogger(__name__)


# ---------------------------------------------
# OSRM configuration
# ---------------------------------------------

OSRM_URL = (
    "https://router.project-osrm.org"
    "/route/v1/driving"
)

OSRM_TIMEOUT = 15


# ---------------------------------------------
# Distance between two coordinates
# ---------------------------------------------

def haversine_distance(
    lat1,
    lon1,
    lat2,
    lon2
):

    try:

        lat1 = float(lat1)
        lon1 = float(lon1)
        lat2 = float(lat2)
        lon2 = float(lon2)

    except (TypeError, ValueError):

        raise ValueError(
            "Invalid coordinates for distance calculation"
        )


    # Validate latitude
    if not -90 <= lat1 <= 90:
        raise ValueError("Invalid latitude")

    if not -90 <= lat2 <= 90:
        raise ValueError("Invalid latitude")


    # Validate longitude
    if not -180 <= lon1 <= 180:
        raise ValueError("Invalid longitude")

    if not -180 <= lon2 <= 180:
        raise ValueError("Invalid longitude")


    R = 6371.0

    lat1 = math.radians(lat1)
    lon1 = math.radians(lon1)

    lat2 = math.radians(lat2)
    lon2 = math.radians(lon2)

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1)
        * math.cos(lat2)
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a)
    )

    return R * c


# ---------------------------------------------
# Calculate hazard penalty
# ---------------------------------------------

def calculate_hazard_penalty(
    route_coordinates,
    hazards
):

    if not isinstance(
        route_coordinates,
        list
    ):

        raise ValueError(
            "Invalid route coordinates"
        )


    if not isinstance(
        hazards,
        list
    ):

        raise ValueError(
            "Hazards must be a list"
        )


    total_penalty = 0

    affected_hazards = []


    for hazard in hazards:

        # Ignore malformed hazard documents
        if not isinstance(
            hazard,
            dict
        ):
            logger.warning(
                "Skipping malformed hazard"
            )
            continue


        location = hazard.get(
            "location",
            {}
        )


        if not isinstance(
            location,
            dict
        ):
            logger.warning(
                "Skipping hazard with invalid location"
            )
            continue


        hazard_lat = location.get("lat")
        hazard_lon = location.get("lon")


        if (
            hazard_lat is None
            or hazard_lon is None
        ):
            logger.warning(
                "Skipping hazard without coordinates"
            )
            continue


        # -----------------------------------------
        # Validate hazard coordinates
        # -----------------------------------------

        try:

            hazard_lat = float(
                hazard_lat
            )

            hazard_lon = float(
                hazard_lon
            )

        except (
            TypeError,
            ValueError
        ):

            logger.warning(
                "Skipping hazard with invalid coordinates"
            )

            continue


        if not -90 <= hazard_lat <= 90:
            logger.warning(
                "Skipping hazard with invalid latitude"
            )
            continue


        if not -180 <= hazard_lon <= 180:
            logger.warning(
                "Skipping hazard with invalid longitude"
            )
            continue


        # -----------------------------------------
        # Severity
        # -----------------------------------------

        try:

            severity = float(
                hazard.get(
                    "damage_severity",
                    0
                )
            )

        except (
            TypeError,
            ValueError
        ):

            logger.warning(
                "Skipping hazard with invalid severity"
            )

            continue


        # Keep severity within expected ML range
        severity = max(
            0.0,
            min(
                severity,
                1.0
            )
        )


        # -----------------------------------------
        # Zone
        # -----------------------------------------

        zone = str(
            hazard.get(
                "zone_classification",
                "safe"
            )
        ).lower()


        # Ignore safe locations
        if zone == "safe":
            continue


        # -----------------------------------------
        # Find closest point on route
        # -----------------------------------------

        closest_distance = float("inf")


        for point in route_coordinates:

            if not isinstance(
                point,
                (list, tuple)
            ):

                continue


            if len(point) < 2:
                continue


            try:

                # OSRM format:
                # [longitude, latitude]

                route_lon = float(
                    point[0]
                )

                route_lat = float(
                    point[1]
                )


                distance = haversine_distance(
                    route_lat,
                    route_lon,
                    hazard_lat,
                    hazard_lon
                )


                closest_distance = min(
                    closest_distance,
                    distance
                )


            except (
                TypeError,
                ValueError
            ):

                continue


        # No valid route point
        if closest_distance == float("inf"):
            continue


        # -----------------------------------------
        # Hazard radius = 500 meters
        # -----------------------------------------

        if closest_distance <= 0.5:

            # Higher severity = higher penalty
            penalty = severity * 100


            # Danger gets additional penalty
            if zone == "danger":

                penalty *= 2


            total_penalty += penalty


            affected_hazards.append({

                "location_id": hazard.get(
                    "location_id"
                ),

                "damage_type": hazard.get(
                    "damage_type",
                    "unknown"
                ),

                "severity": severity,

                "distance_km": round(
                    closest_distance,
                    3
                ),

                "location": {

                    "lat": hazard_lat,

                    "lon": hazard_lon
                }
            })


    return (
        total_penalty,
        affected_hazards
    )


# ---------------------------------------------
# Get routes from OSRM
# ---------------------------------------------

def get_osrm_routes(
    start,
    destination
):

    if not isinstance(
        start,
        dict
    ):

        raise ValueError(
            "start must be an object"
        )


    if not isinstance(
        destination,
        dict
    ):

        raise ValueError(
            "destination must be an object"
        )


    # -----------------------------------------
    # Read coordinates
    # -----------------------------------------

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

    except KeyError as e:

        raise ValueError(
            f"Missing coordinate: {e.args[0]}"
        )

    except (
        TypeError,
        ValueError
    ):

        raise ValueError(
            "Invalid start or destination coordinates"
        )


    # -----------------------------------------
    # Validate coordinates
    # -----------------------------------------

    for latitude in [
        start_lat,
        destination_lat
    ]:

        if not -90 <= latitude <= 90:

            raise ValueError(
                "Latitude must be between -90 and 90"
            )


    for longitude in [
        start_lon,
        destination_lon
    ]:

        if not -180 <= longitude <= 180:

            raise ValueError(
                "Longitude must be between -180 and 180"
            )


    # -----------------------------------------
    # Build OSRM request
    # -----------------------------------------

    coordinates = (
        f"{start_lon},{start_lat};"
        f"{destination_lon},{destination_lat}"
    )


    url = (
        f"{OSRM_URL}/"
        f"{coordinates}"
    )


    params = {

        "alternatives": "true",

        "overview": "full",

        "geometries": "geojson",

        "steps": "false"
    }


    try:

        response = requests.get(
            url,
            params=params,
            timeout=OSRM_TIMEOUT
        )


    except requests.exceptions.Timeout:

        logger.error(
            "OSRM request timed out"
        )

        raise RuntimeError(
            "Routing service timed out"
        )


    except requests.exceptions.ConnectionError:

        logger.error(
            "Could not connect to OSRM"
        )

        raise RuntimeError(
            "Could not connect to routing service"
        )


    except requests.exceptions.RequestException:

        logger.exception(
            "OSRM request failed"
        )

        raise RuntimeError(
            "Routing service request failed"
        )


    # -----------------------------------------
    # HTTP error
    # -----------------------------------------

    try:

        response.raise_for_status()

    except requests.exceptions.HTTPError:

        logger.error(
            "OSRM returned HTTP %s",
            response.status_code
        )

        raise RuntimeError(
            "Routing service returned an error"
        )


    # -----------------------------------------
    # Parse JSON
    # -----------------------------------------

    try:

        data = response.json()

    except ValueError:

        logger.error(
            "OSRM returned invalid JSON"
        )

        raise RuntimeError(
            "Invalid response from routing service"
        )


    # -----------------------------------------
    # Check OSRM response
    # -----------------------------------------

    if data.get("code") != "Ok":

        message = data.get(
            "message",
            "Routing service failed"
        )

        logger.error(
            "OSRM error: %s",
            message
        )

        raise RuntimeError(
            message
        )


    routes = data.get(
        "routes",
        []
    )


    if not isinstance(
        routes,
        list
    ):

        raise RuntimeError(
            "Invalid routes returned by routing service"
        )


    return routes


# ---------------------------------------------
# Main route calculation
# ---------------------------------------------

def calculate_route(
    start,
    destination,
    hazards
):

    # -----------------------------------------
    # Validate hazards
    # -----------------------------------------

    if hazards is None:

        hazards = []


    if not isinstance(
        hazards,
        list
    ):

        raise ValueError(
            "Hazards must be a list"
        )


    # -----------------------------------------
    # Get routes
    # -----------------------------------------

    routes = get_osrm_routes(
        start,
        destination
    )


    if not routes:

        raise RuntimeError(
            "No route found between the given locations"
        )


    evaluated_routes = []


    # -----------------------------------------
    # Evaluate every route
    # -----------------------------------------

    for route in routes:

        if not isinstance(
            route,
            dict
        ):

            logger.warning(
                "Skipping malformed route"
            )

            continue


        geometry = route.get(
            "geometry",
            {}
        )


        if not isinstance(
            geometry,
            dict
        ):

            continue


        route_coordinates = geometry.get(
            "coordinates",
            []
        )


        if not route_coordinates:

            continue


        try:

            hazard_penalty, affected_hazards = (
                calculate_hazard_penalty(
                    route_coordinates,
                    hazards
                )
            )

        except Exception:

            logger.exception(
                "Failed to calculate hazard penalty"
            )

            continue


        # -----------------------------------------
        # Distance
        # -----------------------------------------

        try:

            distance_km = (
                float(
                    route.get(
                        "distance",
                        0
                    )
                ) / 1000
            )

            duration_min = (
                float(
                    route.get(
                        "duration",
                        0
                    )
                ) / 60
            )

        except (
            TypeError,
            ValueError
        ):

            logger.warning(
                "Skipping route with invalid distance/duration"
            )

            continue


        # -----------------------------------------
        # Route score
        # -----------------------------------------

        score = (
            distance_km
            + hazard_penalty
        )


        evaluated_routes.append({

            "route": route_coordinates,

            "distance_km": round(
                distance_km,
                2
            ),

            "estimated_time_min": round(
                duration_min,
                1
            ),

            "hazard_penalty": round(
                hazard_penalty,
                2
            ),

            "hazards": affected_hazards,

            "score": round(
                score,
                2
            )
        })


    # -----------------------------------------
    # No valid route after evaluation
    # -----------------------------------------

    if not evaluated_routes:

        raise RuntimeError(
            "Unable to evaluate available routes"
        )


    # -----------------------------------------
    # Select safest route
    # -----------------------------------------

    best_route = min(
        evaluated_routes,
        key=lambda x: x["score"]
    )


    # -----------------------------------------
    # Determine status
    # -----------------------------------------

    if best_route["hazards"]:

        status = "caution"

    else:

        status = "safe"


    # -----------------------------------------
    # Final response
    # -----------------------------------------

    return {

        "route": best_route[
            "route"
        ],

        "distance_km": best_route[
            "distance_km"
        ],

        "estimated_time_min": best_route[
            "estimated_time_min"
        ],

        "status": status,

        "hazard_penalty": best_route[
            "hazard_penalty"
        ],

        "hazards_considered": len(
            hazards
        ),

        "hazards_on_route": best_route[
            "hazards"
        ]
    }

