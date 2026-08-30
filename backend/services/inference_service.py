
import os
import logging


# ---------------------------------
# Logging
# ---------------------------------

logger = logging.getLogger(__name__)


# ---------------------------------
# Run AI inference
# ---------------------------------

def run_inference(image_path):

    # ---------------------------------
    # 1. Validate image path
    # ---------------------------------

    if not image_path:

        raise ValueError(
            "Image path is required"
        )


    if not isinstance(image_path, str):

        raise TypeError(
            "Image path must be a string"
        )


    # ---------------------------------
    # 2. Check image exists
    # ---------------------------------

    if not os.path.exists(image_path):

        raise FileNotFoundError(
            f"Image file not found: {image_path}"
        )


    # ---------------------------------
    # 3. Check image is not empty
    # ---------------------------------

    if os.path.getsize(image_path) == 0:

        raise ValueError(
            "Image file is empty"
        )


    logger.info(
        "Running inference on image: %s",
        image_path
    )


    try:

        # ---------------------------------
        # Temporary mock model
        # ---------------------------------
        #
        # AI teammate will replace this
        # section with the actual ML model.
        #

        result = {

            "detections": [

                {
                    "class": "fire",

                    "confidence": 0.91,

                    "bbox": [
                        100,
                        100,
                        400,
                        400
                    ]
                }

            ],

            "damage_type": "fire",

            "damage_severity": 0.91,

            "zone_classification": "danger"
        }


    except Exception:

        logger.exception(
            "AI inference failed for image: %s",
            image_path
        )

        raise


    # ---------------------------------
    # 4. Validate model output
    # ---------------------------------

    if not isinstance(result, dict):

        raise ValueError(
            "AI model returned invalid response"
        )


    required_fields = [
        "detections",
        "damage_type",
        "damage_severity",
        "zone_classification"
    ]


    for field in required_fields:

        if field not in result:

            raise ValueError(
                f"AI model response missing field: {field}"
            )


    # ---------------------------------
    # 5. Validate severity
    # ---------------------------------

    try:

        severity = float(
            result["damage_severity"]
        )

    except (TypeError, ValueError):

        raise ValueError(
            "AI model returned invalid damage_severity"
        )


    if not 0 <= severity <= 1:

        raise ValueError(
            "damage_severity must be between 0 and 1"
        )


    result["damage_severity"] = severity


    # ---------------------------------
    # 6. Validate detections
    # ---------------------------------

    if not isinstance(
        result["detections"],
        list
    ):

        raise ValueError(
            "detections must be a list"
        )


    # ---------------------------------
    # 7. Validate zone classification
    # ---------------------------------

    valid_zones = {
        "safe",
        "caution",
        "danger"
    }


    zone = str(
        result["zone_classification"]
    ).lower()


    if zone not in valid_zones:

        raise ValueError(
            "Invalid zone_classification"
        )


    result["zone_classification"] = zone


    logger.info(
        "Inference completed successfully"
    )


    return result

