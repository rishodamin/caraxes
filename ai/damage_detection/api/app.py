from fastapi import FastAPI, UploadFile, File
from ultralytics import YOLO
import io
from PIL import Image

app = FastAPI(title="Caraxes Disaster AI Inference Engine", version="1.0")

# Load your newly trained custom model weights from the repo path
model = YOLO('/content/caraxes/ai/damage_detection/weights/best_hazard.pt')

# Severity mapping for the backend priority engine
SEVERITY_MAP = {
    "collapsed_building": {"priority": 1, "severity_score": 100, "action": "Dispatch Heavy Rescue"},
    "fire_smoke": {"priority": 2, "severity_score": 80, "action": "Alert Fire & Emergency Services"},
    "flooded_road": {"priority": 3, "severity_score": 60, "action": "Trigger Automated Road Closure"}
}

@app.post("/predict")
async def predict_hazard(file: UploadFile = File(...)):
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    
    # Run YOLO inference
    results = model(image)[0]
    
    detections = []
    for box in results.boxes:
        cls_id = int(box.cls[0])
        class_name = results.names[cls_id]
        conf = float(box.conf[0])
        xyxy = box.xyxy[0].tolist() # [x1, y1, x2, y2]
        
        hazard_info = SEVERITY_MAP.get(class_name, {"priority": 4, "severity_score": 40, "action": "Monitor Area"})
        
        detections.append({
            "class_name": class_name,
            "confidence": round(conf, 3),
            "bounding_box": {
                "x1": round(xyxy[0], 2),
                "y1": round(xyxy[1], 2),
                "x2": round(xyxy[2], 2),
                "y2": round(xyxy[3], 2)
            },
            "severity_engine": hazard_info
        })
        
    return {
        "status": "success",
        "total_hazards_detected": len(detections),
        "detections": detections
    }

@app.get("/")
def home():
    return {"message": "Caraxes AI Hazard Detection Service is live."}
