from flask import Flask, request, jsonify
from flask_cors import CORS
from firebase_config import db  # Ensure you have firebase_config.py set up with Firestore
import uuid  # To generate a unique user ID
import os
import insightface
from insightface.app import FaceAnalysis
import numpy as np
from PIL import Image, ImageOps
import pandas as pd
from threading import Event, Thread
from sklearn.metrics.pairwise import cosine_similarity




app = Flask(__name__)
CORS(app)

#Initialize FaceAnalysis
app_face = FaceAnalysis()
app_face.prepare(ctx_id=0, det_size=(640, 640))


@app.route("/create_user", methods=["POST"])
def create_user():
    data = request.json
    print(f"Data: {data}")
    if not data or "email" not in data:
        return jsonify({"error": "Email is required"}), 400
    
    email = data["email"]
    password = data["password"] # Hash the password
    first_name = data["first_name"]
    last_name = data["last_name"]
    user_id = str(uuid.uuid4())  # Generate a unique user ID
    email_exists = db.collection("users").where("email", "==", email).get()
    if email_exists:
        return jsonify({"error": "Email already exists"}), 400
    else:
    # Store user in Firestore
        db.collection("users").document(user_id).set({
            "user_id": user_id,
            "email": email,
            "password": password,
            "last_name": last_name,
            "first_name": first_name,
            "detection" : False
        })
    return jsonify({"message": "User created successfully", "user_id": user_id})


@app.route("/authenticate", methods=["POST"])
def authenticate():
    data = request.json
    print(f"Data: {data}")
    if not data or "email" not in data:
        return jsonify({"error": "Email is required"}), 400
    email = data["email"]
    password = data["password"] # Hash the password
    user = db.collection("users").where("email", "==", email).where("password", "==", password).get()
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
    email = request.form.get("email")
    password = request.form.get("password")
    num_embeddings = request.form.get("num_embeddings")
    embedding_string = "Embedding" + num_embeddings
    user = db.collection("users").where("email", "==", email).where("password", "==", password).get()

    user_doc = user[0].reference
    if file.filename == '':
        return jsonify({"error": "File is required"}), 400
    

    #save file to the upload folder
    file_path = os.path.join("/Users/admin/Desktop/SWE Projects/Flutter Projects/Facial Recognition App/facial_recognition/backend/uploads", file.filename)
    file.save(file_path)
    embedding = get_embeddings(file_path).tolist()

    if embedding is None:
        return jsonify({"error": "No face found in the image"}), 400
    user_doc.update({
        embedding_string: embedding
    })

    return jsonify({"message": "File uploaded successfully"}), 200

def get_embeddings(file_path):
    try:
        img = Image.open(file_path)
        img = ImageOps.exif_transpose(img)
        img = img.convert("RGB")
        img_array = np.asarray(img)

        faces = app_face.get(img_array)

        if len(faces) == 0:
            print("No faces found in the image")
            return None
        
        embedding = faces[0].embedding

    except Exception as e:
        print(f"Error processing image: {e}")
        return None

    return embedding


@app.route("/detection", methods=["POST"])
def detection():
    print("Receiving file...")
    #using distance based classification
    file = request.files['image']
    email = request.form["email"]
    password = request.form["password"]
    user = db.collection("users").where("email", "==", email).where("password", "==", password).get()
    user_doc = user[0]
    user_data = user_doc.to_dict()
    print(user_data.get("detection"))
    file_path = os.path.join("/Users/admin/Desktop/SWE Projects/Flutter Projects/Facial Recognition App/facial_recognition/backend/uploads", file.filename)
    file.save(file_path)
    #really rough function to just to see if functionality even works
    if user_data.get("detection") == True:
        embedding_1 = np.array(user_data.get("Embedding0"))
        embedding_2 = np.array(user_data.get("Embedding1"))
        embedding_3 = np.array(user_data.get("Embedding2"))
        embedding_mean = np.mean([embedding_1, embedding_2, embedding_3], axis=0)
        #retrieve embeddings from the incoming photo file
        embedding = np.array(get_embeddings(file_path))
        if embedding is None:
            return jsonify({"error": "No face found in the image"}), 403
        #calculate cosine similarity
        similarity = cosine_similarity([embedding], [embedding_mean]).flatten()[0]
        print(f"similarity: {similarity}")
        if similarity > 0.6:
            user_doc.reference.update({
                "detection": False
            })
            return jsonify({"message": "User detected"}), 200
        else:
            return jsonify({"message": "User not detected"}), 400
        
    else:
        return jsonify({"error": "Ticket is inactive. Try Again"}), 400
    

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)





