from flask import Flask
from flask_cors import CORS

from routes.prediction import prediction_bp
from routes.routing import routing_bp


app = Flask(__name__)

CORS(app)

app.config["MAX_CONTENT_LENGTH"] = (
    10 * 1024 * 1024
)


app.register_blueprint(
    prediction_bp
)

app.register_blueprint(
    routing_bp
)


@app.route("/")
def home():

    return {
        "status": "success",
        "message": "Disaster Response API is running"
    }


if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )