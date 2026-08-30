from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import os
import uuid

from services.inference_service import run_inference


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

os.makedirs(
    UPLOAD_FOLDER,
    exist_ok=True
)


def allowed_file(filename):
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower()
        in ALLOWED_EXTENSIONS
    )


@prediction_bp.route("/infer", methods=["POST"])
def infer():

    # -------------------------
    # 1. Check image
    # -------------------------

    if "image" not in request.files:
        return jsonify({
            "success": False,
            "error": "Image is required"
        }), 400

    image = request.files["image"]

    if image.filename == "":
        return jsonify({
            "success": False,
            "error": "No image selected"
        }), 400

    if not allowed_file(image.filename):
        return jsonify({
            "success": False,
            "error": "Only JPG, JPEG and PNG images are allowed"
        }), 400

    # -------------------------
    # 2. Get metadata
    # -------------------------

    image_id = request.form.get("image_id")

    if not image_id:
        return jsonify({
            "success": False,
            "error": "image_id is required"
        }), 400

    location_id = request.form.get("location_id")

    if not location_id:
        return jsonify({
            "success": False,
            "error": "location_id is required"
        }), 400

    source_type = request.form.get(
        "source_type",
        "citizen"
    )

    lat = request.form.get("lat")
    lon = request.form.get("lon")

    # -------------------------
    # 3. Generate unique filename
    # -------------------------

    extension = image.filename.rsplit(
        ".",
        1
    )[1].lower()

    filename = (
        f"{uuid.uuid4().hex}.{extension}"
    )

    image_path = os.path.join(
        UPLOAD_FOLDER,
        filename
    )

    image.save(image_path)

    # -------------------------
    # 4. AI inference
    # -------------------------

    try:

        ai_result = run_inference(
            image_path
        )

    except Exception as e:

        return jsonify({
            "success": False,
            "error": "AI inference failed",
            "details": str(e)
        }), 500

    # -------------------------
    # 5. Build response
    # -------------------------

    response = {
        "success": True,

        "image_id": image_id,

        "location_id": location_id,

        "source_type": source_type,

        "location": {
            "lat": float(lat) if lat else None,
            "lon": float(lon) if lon else None
        },

        "timestamp": datetime.now(
            timezone.utc
        ).isoformat(),

        "detections": ai_result.get(
            "detections",
            []
        ),

        "damage_type": ai_result.get(
            "damage_type",
            "unknown"
        ),

        "damage_severity": ai_result.get(
            "damage_severity",
            0
        ),

        "zone_classification": ai_result.get(
            "zone_classification",
            "safe"
        )
    }

    return jsonify(response), 200