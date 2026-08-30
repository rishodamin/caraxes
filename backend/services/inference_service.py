def run_inference(image_path):

    print("Received image:", image_path)

    # Temporary response
    # AI teammate will replace this later

    return {
        "detections": [
            {
                "class": "fire",
                "confidence": 0.91,
                "bbox": [100, 100, 400, 400]
            }
        ],

        "damage_type": "fire",

        "damage_severity": 0.91,

        "zone_classification": "danger"
    }