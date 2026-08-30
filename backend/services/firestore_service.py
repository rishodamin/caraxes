import os
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore


# ---------------------------------
# Firebase initialization
# ---------------------------------

BASE_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

SERVICE_ACCOUNT_PATH = os.path.join(
    BASE_DIR,
    "serviceAccountKey.json"
)


if not firebase_admin._apps:

    cred = credentials.Certificate(
        SERVICE_ACCOUNT_PATH
    )

    firebase_admin.initialize_app(
        cred
    )


db = firestore.client()


# ---------------------------------
# Save disaster report
# ---------------------------------

def save_disaster_report(
    location_id,
    image_id,
    report_data
):

    document_data = {

        "location_id": location_id,

        "image_id": image_id,

        "source_type": report_data.get(
            "source_type",
            "citizen"
        ),

        "location": report_data.get(
            "location",
            {}
        ),

        "timestamp": report_data.get(
            "timestamp"
        ),

        "detections": report_data.get(
            "detections",
            []
        ),

        "damage_type": report_data.get(
            "damage_type",
            "unknown"
        ),

        "damage_severity": report_data.get(
            "damage_severity",
            0
        ),

        "zone_classification": report_data.get(
            "zone_classification",
            "safe"
        )
    }

    db.collection(
        "disaster_locations"
    ).document(
        location_id
    ).set(
        document_data
    )

    return True


# ---------------------------------
# Get all disaster locations
# ---------------------------------

def get_all_hazards():

    docs = (
        db.collection(
            "disaster_locations"
        ).stream()
    )

    hazards = []

    for doc in docs:

        data = doc.to_dict()

        data["location_id"] = doc.id

        hazards.append(data)

    return hazards