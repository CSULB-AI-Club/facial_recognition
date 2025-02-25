from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_config import db  # Ensure you have firebase_config.py set up with Firestore
import uuid  # To generate a unique user ID

app = Flask(__name__)
CORS(app)

@app.route("/create_user", methods=["POST"])
def create_user():
    data = request.json
    print(f"Data: {data}")
    if not data or "email" not in data:
        return jsonify({"error": "Email is required"}), 400

    email = data["email"]
    user_id = str(uuid.uuid4())  # Generate a unique user ID

    # Store user in Firestore
    db.collection("users").document(user_id).set({
        "user_id": user_id,
        "email": email
    })

    return jsonify({"message": "User created successfully", "user_id": user_id})

if __name__ == "__main__":
    app.run(debug=True)





