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
    password = data["password"]
    print(password)
    user_id = str(uuid.uuid4())  # Generate a unique user ID
    email_exists = db.collection("users").where("email", "==", email).get()
    if email_exists:
        return jsonify({"error": "Email already exists"}), 400
    else:
    # Store user in Firestore
        db.collection("users").document(user_id).set({
            "user_id": user_id,
            "email": email,
            "password": password
        })
    return jsonify({"message": "User created successfully", "user_id": user_id})


@app.route("/authenticate", methods=["POST"])
def authenticate():
    data = request.json
    print(f"Data: {data}")
    if not data or "email" not in data:
        return jsonify({"error": "Email is required"}), 400
    email = data["email"]
    password = data["password"]
    user = db.collection("users").where("email", "==", email).where("password", "==", password).get()
    print(f"User: {user}")
    if not user:
        return jsonify({"error": "User not found"}), 404
    else:
        return jsonify({"message": "User authenticated successfully"}), 200




if __name__ == "__main__":
    app.run(debug=True)





