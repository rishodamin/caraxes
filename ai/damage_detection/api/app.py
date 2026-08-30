from fastapi import FastAPI, UploadFile, File
from ultralytics import YOLO
import io
from PIL import Image
from pathlib import Path

app = FastAPI(
    title="Caraxes Disaster AI Inference Engine",
    version="1.0"
)


# ---------------------------------
# Model
# ---------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_PATH = BASE_DIR / "weights" / "best_hazard.pt"

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model not found: {MODEL_PATH}"
    )

model = YOLO(str(MODEL_PATH))

print(f"Loaded model: {MODEL_PATH}")
print(f"Classes: {model.names}")


# ---------------------------------
# Severity mapping
# ---------------------------------

SEVERITY_MAP = {
    "collapsed_building": {
        "priority": 1,
        "severity_score": 100,
        "action": "Dispatch Heavy Rescue"
    },

    "fire_smoke": {
        "priority": 2,
        "severity_score": 80,
        "action": "Alert Fire & Emergency Services"
    },

    "flooded_road": {
        "priority": 3,
        "severity_score": 60,
        "action": "Trigger Automated Road Closure"
    }
}


# ---------------------------------
# Prediction
# ---------------------------------

@app.post("/predict")
async def predict_hazard(
    file: UploadFile = File(...)
):

    # ---------------------------------
    # Read image
    # ---------------------------------

    image_bytes = await file.read()

    print(
        f"Received image: {file.filename}"
    )

    print(
        f"Image size: {len(image_bytes)} bytes"
    )

    image = Image.open(
        io.BytesIO(image_bytes)
    ).convert("RGB")


    print(
        f"Image dimensions: {image.size}"
    )


    # ---------------------------------
    # Run YOLO inference
    # ---------------------------------

    results = model.predict(
        source=image,
        conf=0.10,
        verbose=True
    )[0]


    # ---------------------------------
    # Debug detection results
    # ---------------------------------

    print(
        "NUMBER OF BOXES:",
        len(results.boxes)
    )


    detections = []


    # ---------------------------------
    # Extract detections
    # ---------------------------------

    for box in results.boxes:

        cls_id = int(
            box.cls[0]
        )

        class_name = results.names[
            cls_id
        ]

        conf = float(
            box.conf[0]
        )

        xyxy = box.xyxy[
            0
        ].tolist()


        print(
            "DETECTED:",
            class_name,
            "CONFIDENCE:",
            conf
        )


        # ---------------------------------
        # Severity information
        # ---------------------------------

        hazard_info = SEVERITY_MAP.get(
            class_name,

            {
                "priority": 4,
                "severity_score": 40,
                "action": "Monitor Area"
            }
        )


        # ---------------------------------
        # Add detection
        # ---------------------------------

        detections.append({

            "class_name": class_name,

            "confidence": round(
                conf,
                3
            ),

            "bounding_box": {

                "x1": round(
                    xyxy[0],
                    2
                ),

                "y1": round(
                    xyxy[1],
                    2
                ),

                "x2": round(
                    xyxy[2],
                    2
                ),

                "y2": round(
                    xyxy[3],
                    2
                )
            },

            "severity_engine":
                hazard_info
        })


    # ---------------------------------
    # Final response
    # ---------------------------------

    print(
        "TOTAL HAZARDS:",
        len(detections)
    )


    return {

        "status": "success",

        "total_hazards_detected":
            len(detections),

        "detections":
            detections
    }


# ---------------------------------
# Health check
# ---------------------------------

@app.get("/")
def home():

    return {
        "message":
            "Caraxes AI Hazard Detection Service is live."
    }