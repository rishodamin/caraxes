
from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import os
import uuid
import logging

from services.inference_service import run_inference
from services.firestore_service import save_disaster_report


prediction_bp = Blueprint(
    "prediction",
    __name__
)


UPLOAD_FOLDER = "uploads"

ALLOWED_EXTENSIONS = {
    "jpg",
    "jpeg",
    "png"
}

ALLOWED_SOURCE_TYPES = {
    "citizen",
    "drone",
    "satellite"
}


os.makedirs(
    UPLOAD_FOLDER,
    exist_ok=True
)


# --------------------------------
# Logging
# --------------------------------

logger = logging.getLogger(__name__)


# --------------------------------
# Check allowed image extension
# --------------------------------

def allowed_file(filename):

    return (
        "." in filename
        and filename.rsplit(
            ".",
            1
        )[1].lower()
        in ALLOWED_EXTENSIONS
    )


# --------------------------------
# Validate coordinates
# --------------------------------

def parse_coordinate(value, field_name):

    if value is None or value == "":
        return None

    try:

        coordinate = float(value)

    except (TypeError, ValueError):

        raise ValueError(
            f"{field_name} must be a valid number"
        )

    # Latitude range
    if field_name == "lat":

        if not -90 <= coordinate <= 90:

            raise ValueError(
                "Latitude must be between -90 and 90"
            )

    # Longitude range
    if field_name == "lon":

        if not -180 <= coordinate <= 180:

            raise ValueError(
                "Longitude must be between -180 and 180"
            )

    return coordinate


@prediction_bp.route(
    "/infer",
    methods=["POST"]
)
def infer():

    # --------------------------------
    # 1. Check request content
    # --------------------------------

    if not request.files:

        return jsonify({
            "success": False,
            "error": "Multipart form data with an image is required"
        }), 400


    # --------------------------------
    # 2. Check image
    # --------------------------------

    if "image" not in request.files:

        return jsonify({
            "success": False,
            "error": "Image is required"
        }), 400


    image = request.files["image"]


    if image.filename is None or image.filename == "":

        return jsonify({
            "success": False,
            "error": "No image selected"
        }), 400


    if not allowed_file(image.filename):

        return jsonify({
            "success": False,
            "error": (
                "Only JPG, JPEG and PNG "
                "images are allowed"
            )
        }), 400


    # --------------------------------
    # 3. Get metadata
    # --------------------------------

    image_id = request.form.get(
        "image_id"
    )


    if not image_id:

        return jsonify({
            "success": False,
            "error": "image_id is required"
        }), 400


    location_id = request.form.get(
        "location_id"
    )


    if not location_id:

        return jsonify({
            "success": False,
            "error": "location_id is required"
        }), 400


    source_type = request.form.get(
        "source_type",
        "citizen"
    ).lower()


    if source_type not in ALLOWED_SOURCE_TYPES:

        return jsonify({
            "success": False,
            "error": (
                "Invalid source_type. "
                "Allowed values: citizen, drone, satellite"
            )
        }), 400


    # --------------------------------
    # 4. Validate coordinates
    # --------------------------------

    try:

        lat = parse_coordinate(
            request.form.get("lat"),
            "lat"
        )

        lon = parse_coordinate(
            request.form.get("lon"),
            "lon"
        )

    except ValueError as e:

        return jsonify({
            "success": False,
            "error": str(e)
        }), 400


    # --------------------------------
    # 5. Generate filename
    # --------------------------------

    extension = image.filename.rsplit(
        ".",
        1
    )[1].lower()


    filename = (
        f"{uuid.uuid4().hex}."
        f"{extension}"
    )


    image_path = os.path.join(
        UPLOAD_FOLDER,
        filename
    )


    # --------------------------------
    # 6. Save uploaded image
    # --------------------------------

    try:

        image.save(
            image_path
        )

    except Exception:

        logger.exception(
            "Failed to save uploaded image"
        )

        return jsonify({
            "success": False,
            "error": "Failed to save image"
        }), 500


    # --------------------------------
    # 7. AI inference
    # --------------------------------

    try:

        ai_result = run_inference(
            image_path
        )

    except Exception:

        logger.exception(
            "AI inference failed for image_id=%s",
            image_id
        )

        # Remove uploaded image if inference fails
        try:

            if os.path.exists(image_path):
                os.remove(image_path)

        except OSError:

            logger.exception(
                "Failed to remove image after inference failure"
            )


        return jsonify({
            "success": False,
            "error": "AI inference failed"
        }), 500


    # --------------------------------
    # 8. Validate AI response
    # --------------------------------

    if not isinstance(ai_result, dict):

        logger.error(
            "Invalid AI response for image_id=%s",
            image_id
        )

        return jsonify({
            "success": False,
            "error": "Invalid response from AI model"
        }), 500


    if ai_result.get("status") != "success":

        logger.error(
            "AI inference unsuccessful for image_id=%s",
            image_id
        )

        return jsonify({
            "success": False,
            "error": "AI model inference was not successful"
        }), 500


    detections = ai_result.get(
        "detections",
        []
    )


    if not isinstance(detections, list):

        logger.error(
            "Invalid detections returned by AI for image_id=%s",
            image_id
        )

        return jsonify({
            "success": False,
            "error": "Invalid detections returned by AI model"
        }), 500


    # --------------------------------
    # 9. Build response using actual AI contract
    # --------------------------------

    response = {

        "success": True,

        "image_id": image_id,

        "location_id": location_id,

        "source_type": source_type,

        "location": {

            "lat": lat,

            "lon": lon
        },

        "timestamp": datetime.now(
            timezone.utc
        ).isoformat(),

        "status": ai_result.get(
            "status",
            "success"
        ),

        "total_hazards_detected": ai_result.get(
            "total_hazards_detected",
            len(detections)
        ),

        "detections": detections
    }


    # --------------------------------
    # 10. Save result to Firestore
    # --------------------------------

    try:

        save_disaster_report(
            location_id,
            image_id,
            response
        )

    except Exception:

        logger.exception(
            "Failed to save disaster result "
            "for location_id=%s, image_id=%s",
            location_id,
            image_id
        )

        return jsonify({
            "success": False,
            "error": "Failed to save disaster result"
        }), 500


    # --------------------------------
    # 11. Return result
    # --------------------------------

    return jsonify(
        response
    ), 200

