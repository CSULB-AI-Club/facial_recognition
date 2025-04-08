from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_config import db  # Ensure you have firebase_config.py set up with Firestore
import uuid  # To generate a unique user ID
import os
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

<<<<<<< Updated upstream
=======

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


@app.route("/upload", methods=["POST"])
def upload():
    print("Receiving file...")
    if 'image' not in request.files:
        return jsonify({"error": "File is required"}), 400
    
    file = request.files['image']

    if file.filename == '':
        return jsonify({"error": "File is required"}), 400
    
    #save file to the upload folder
    file_path = os.path.join("/Users/admin/Desktop/SWE Projects/Flutter Projects/Facial Recognition App/facial_recognition/backend/uploads", file.filename)
    file.save(file_path)

    return jsonify({"message": "File uploaded successfully"}), 200



>>>>>>> Stashed changes
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)





