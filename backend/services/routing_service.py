def calculate_route(
    start,
    destination,
    hazards
):

    # --------------------------------
    # Temporary mock route
    # --------------------------------
    #
    # Later this function will contain
    # the actual routing algorithm.
    #

    start_lat = float(start["lat"])
    start_lon = float(start["lon"])

    destination_lat = float(
        destination["lat"]
    )

    destination_lon = float(
        destination["lon"]
    )

    # Simple intermediate point
    mid_lat = (
        start_lat + destination_lat
    ) / 2

    mid_lon = (
        start_lon + destination_lon
    ) / 2

    route = [
        [
            start_lat,
            start_lon
        ],
        [
            mid_lat,
            mid_lon
        ],
        [
            destination_lat,
            destination_lon
        ]
    ]

    return {
        "route": route,

        "distance_km": 2.4,

        "estimated_time_min": 7,

        "status": "safe",

        "hazards_considered": len(
            hazards
        )
    }