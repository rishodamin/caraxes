from flask import Blueprint, request, jsonify
import os
from werkzeug.utils import secure_filename

prediction_bp = Blueprint("prediction", __name__)

UPLOAD_FOLDER = "uploads"
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg"}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def allowed_file(filename):
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
    )


@prediction_bp.route("/predict", methods=["POST"])
def predict():

    if "image" not in request.files:
        return jsonify({
            "error": "No image provided"
        }), 400

    image = request.files["image"]

    if image.filename == "":
        return jsonify({
            "error": "No image selected"
        }), 400

    if not allowed_file(image.filename):
        return jsonify({
            "error": "Unsupported image format"
        }), 400

    filename = secure_filename(image.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)

    image.save(filepath)

    # AI model will be called here
    prediction = {
        "damage_detected": True,
        "damage_type": "bridge_damage",
        "severity": "severe",
        "confidence": 0.91
    }

    return jsonify({
        "success": True,
        "prediction": prediction
    })