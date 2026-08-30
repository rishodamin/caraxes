
import os
import logging
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore
from google.api_core.exceptions import GoogleAPIError


# ---------------------------------
# Logging
# ---------------------------------

logger = logging.getLogger(__name__)


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


# Check service account file
if not os.path.exists(SERVICE_ACCOUNT_PATH):

    raise FileNotFoundError(
        "Firebase service account file not found"
    )


try:

    if not firebase_admin._apps:

        cred = credentials.Certificate(
            SERVICE_ACCOUNT_PATH
        )

        firebase_admin.initialize_app(
            cred
        )

    db = firestore.client()

except Exception:

    logger.exception(
        "Failed to initialize Firebase"
    )

    raise


# ---------------------------------
# Save disaster report
# ---------------------------------

def save_disaster_report(
    location_id,
    image_id,
    report_data
):

    # Validate location_id
    if not location_id:

        raise ValueError(
            "location_id is required"
        )


    # Validate image_id
    if not image_id:

        raise ValueError(
            "image_id is required"
        )


    # Validate report data
    if not isinstance(report_data, dict):

        raise ValueError(
            "report_data must be a dictionary"
        )


    # ---------------------------------
    # Extract actual AI response
    # ---------------------------------

    detections = report_data.get(
        "detections",
        []
    )


    if not isinstance(detections, list):

        raise ValueError(
            "detections must be a list"
        )


    total_hazards = report_data.get(
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
    # Validate location
    # ---------------------------------

    location = report_data.get(
        "location",
        {}
    )


    if not isinstance(
        location,
        dict
    ):

        raise ValueError(
            "location must be an object"
        )


    # ---------------------------------
    # Build Firestore document
    # ---------------------------------

    document_data = {

        "location_id": location_id,

        "image_id": image_id,

        "source_type": report_data.get(
            "source_type",
            "citizen"
        ),

        "location": location,

        "timestamp": report_data.get(
            "timestamp"
        ),

        "status": report_data.get(
            "status",
            "success"
        ),

        "total_hazards_detected": total_hazards,

        "detections": detections
    }


    # ---------------------------------
    # Save to Firestore
    # ---------------------------------

    try:

        db.collection(
            "disaster_locations"
        ).document(
            location_id
        ).set(
            document_data
        )

    except GoogleAPIError:

        logger.exception(
            "Firestore error while saving "
            "location_id=%s",
            location_id
        )

        raise

    except Exception:

        logger.exception(
            "Unexpected error while saving "
            "location_id=%s",
            location_id
        )

        raise


    logger.info(
        "Disaster report saved successfully "
        "for location_id=%s, image_id=%s",
        location_id,
        image_id
    )


    return True


# ---------------------------------
# Get all disaster locations
# ---------------------------------

def get_all_hazards():

    try:

        docs = (
            db.collection(
                "disaster_locations"
            ).stream()
        )

        hazards = []

        for doc in docs:

            try:

                data = doc.to_dict()

                if not isinstance(
                    data,
                    dict
                ):

                    logger.warning(
                        "Skipping malformed Firestore "
                        "document: %s",
                        doc.id
                    )

                    continue


                data["location_id"] = doc.id

                hazards.append(
                    data
                )

            except Exception:

                logger.exception(
                    "Failed to process Firestore "
                    "document: %s",
                    doc.id
                )


        return hazards


    except GoogleAPIError:

        logger.exception(
            "Firestore error while retrieving "
            "disaster locations"
        )

        raise


    except Exception:

        logger.exception(
            "Unexpected error while retrieving "
            "disaster locations"
        )

        raise

