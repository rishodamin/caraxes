
import os
import logging
import requests


# ---------------------------------
# Logging
# ---------------------------------

logger = logging.getLogger(__name__)


# ---------------------------------
# FastAPI AI service
# ---------------------------------

AI_SERVICE_URL = os.getenv(
    "AI_SERVICE_URL",
    "http://127.0.0.1:8000/predict"
)


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
        "Sending image to AI service: %s",
        image_path
    )


    # ---------------------------------
    # 4. Send image to FastAPI AI service
    # ---------------------------------

    try:

        # Determine MIME type from file extension
        extension = os.path.splitext(
            image_path
        )[1].lower()

        mime_types = {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png"
        }

        content_type = mime_types.get(
            extension,
            "application/octet-stream"
        )


        with open(image_path, "rb") as image_file:

            response = requests.post(
                AI_SERVICE_URL,

                files={
                    "file": (
                        os.path.basename(image_path),
                        image_file,
                        content_type
                    )
                },

                timeout=120
            )


        # Raise exception for HTTP 4xx/5xx
        response.raise_for_status()


    except requests.exceptions.RequestException:

        logger.exception(
            "AI service request failed for image: %s",
            image_path
        )

        raise RuntimeError(
            "Unable to communicate with AI inference service"
        )


    # ---------------------------------
    # 5. Parse AI response
    # ---------------------------------

    try:

        result = response.json()

    except ValueError:

        logger.error(
            "AI service returned invalid JSON: %s",
            response.text
        )

        raise ValueError(
            "AI service returned invalid JSON response"
        )


    # ---------------------------------
    # 6. Validate AI response
    # ---------------------------------

    if not isinstance(result, dict):

        raise ValueError(
            "AI model returned invalid response"
        )


    if result.get("status") != "success":

        raise ValueError(
            "AI model inference was not successful"
        )


    # ---------------------------------
    # 7. Validate detections
    # ---------------------------------

    detections = result.get(
        "detections",
        []
    )


    if not isinstance(detections, list):

        raise ValueError(
            "detections must be a list"
        )


    # ---------------------------------
    # 8. Validate total hazards
    # ---------------------------------

    total_hazards = result.get(
        "total_hazards_detected",
        len(detections)
    )


    if not isinstance(
        total_hazards,
        int
    ):

        raise ValueError(
            "total_hazards_detected must be an integer"
        )


    # ---------------------------------
    # 9. Return actual AI response
    # ---------------------------------

    logger.info(
        "Inference completed successfully. "
        "Detected %d hazards.",
        total_hazards
    )


    return {
        "status": result.get(
            "status",
            "success"
        ),

        "total_hazards_detected": total_hazards,

        "detections": detections
    }

