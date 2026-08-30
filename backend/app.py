from flask import Flask
from routes.prediction import prediction_bp

app = Flask(__name__)

app.register_blueprint(prediction_bp, url_prefix="/api")

if __name__ == "__main__":
    app.run(debug=True)