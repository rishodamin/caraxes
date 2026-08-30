import math
import requests


OSRM_URL = (
    "https://router.project-osrm.org"
    "/route/v1/driving"
)


# --------------------------------------------------
# Distance between two latitude/longitude points
# --------------------------------------------------

def haversine_distance(
    lat1,
    lon1,
    lat2,
    lon2
):

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


# --------------------------------------------------
# Calculate hazard penalty
# --------------------------------------------------

def calculate_hazard_penalty(
    route_coordinates,
    hazards
):

    total_penalty = 0

    affected_hazards = []

    for hazard in hazards:

        location = hazard.get(
            "location",
            {}
        )

        hazard_lat = location.get("lat")
        hazard_lon = location.get("lon")

        if (
            hazard_lat is None
            or hazard_lon is None
        ):
            continue

        hazard_lat = float(hazard_lat)
        hazard_lon = float(hazard_lon)

        severity = float(
            hazard.get(
                "damage_severity",
                0
            )
        )

        zone = hazard.get(
            "zone_classification",
            "safe"
        ).lower()

        # Ignore safe locations
        if zone == "safe":
            continue

        # Find closest point on route
        closest_distance = float("inf")

        for point in route_coordinates:

            # OSRM returns [longitude, latitude]
            route_lon = point[0]
            route_lat = point[1]

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

        # Hazard radius = 500 meters
        if closest_distance <= 0.5:

            # Higher severity = higher penalty
            penalty = severity * 100

            # Danger gets additional penalty
            if zone == "danger":
                penalty *= 2

            total_penalty += penalty

            # --------------------------------------
            # Include hazard coordinates for frontend
            # --------------------------------------

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


# --------------------------------------------------
# Get routes from OSRM
# --------------------------------------------------

def get_osrm_routes(
    start,
    destination
):

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

    response = requests.get(
        url,
        params=params,
        timeout=15
    )

    response.raise_for_status()

    data = response.json()

    if data.get("code") != "Ok":

        raise Exception(
            data.get(
                "message",
                "OSRM routing failed"
            )
        )

    return data.get(
        "routes",
        []
    )


# --------------------------------------------------
# Main route calculation
# --------------------------------------------------

def calculate_route(
    start,
    destination,
    hazards
):

    routes = get_osrm_routes(
        start,
        destination
    )

    if not routes:

        raise Exception(
            "No route found"
        )

    evaluated_routes = []

    for route in routes:

        geometry = route.get(
            "geometry",
            {}
        )

        route_coordinates = geometry.get(
            "coordinates",
            []
        )

        hazard_penalty, affected_hazards = (
            calculate_hazard_penalty(
                route_coordinates,
                hazards
            )
        )

        distance_km = (
            route.get(
                "distance",
                0
            ) / 1000
        )

        duration_min = (
            route.get(
                "duration",
                0
            ) / 60
        )

        # ------------------------------------------
        # Route score
        # ------------------------------------------

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

    # ------------------------------------------
    # Select lowest-score route
    # ------------------------------------------

    best_route = min(
        evaluated_routes,
        key=lambda x: x["score"]
    )

    if best_route["hazards"]:
        status = "caution"
    else:
        status = "safe"

    return {

        "route": best_route["route"],

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