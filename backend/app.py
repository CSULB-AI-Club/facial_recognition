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
from firebase_admin import auth


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
    first_name = data["first_name"]
    last_name = data["last_name"]  # Generate a unique user ID
    user_id = data["uid"]
    email_exists = db.collection("users").where("user_id", "==", user_id).get()
    if email_exists:
        return jsonify({"error": "Email already exists"}), 400
    else:
    # Store user in Firestore
        db.collection("users").document(user_id).set({
            "email": email,
            "last_name": last_name,
            "first_name": first_name,
            "detection" : True,
            "user_id": user_id,
        })
    return jsonify({"message": "User created successfully", "user_id": user_id})



@app.route("/authenticate", methods=["POST"])
def authenticate():
    data = request.json
    print(f"Data: {data}")
    if not data:
        return jsonify({"error": "No data"}), 400
    user_id = data["uid"]
    user = db.collection("users").where("user_id", "==", user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    else:
        try:
            custom_token = auth.create_custom_token(user_id)
        except Exception as e:
            print(f"Error authenticating user: {e}")
            return jsonify({"error": "Authentication failed"}), 500
        return jsonify({"message": "User authenticated successfully", "token": custom_token.decode("utf-8")}), 200


@app.route("/upload", methods=["POST"])
def upload():
    print("Receiving file...")
    if 'image' not in request.files:
        return jsonify({"error": "File is required"}), 400
    
    file = request.files['image']
    uid = request.form.get("uid")
    num_embeddings = request.form.get("num_embeddings")
    embedding_string = "Embedding" + num_embeddings
    user = db.collection("users").where("user_id", "==", uid).get()

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

    return jsonify({"message": "Face Embeddings uploaded successfully"}), 200

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
    uid = request.form.get("uid")
    user = db.collection("users").where("user_id", "==", uid).get()
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
        print("Embedding mean sample: ", embedding_mean[:5])
        #retrieve embeddings from the incoming photo file
        embedding = np.array(get_embeddings(file_path))
        if embedding is None:
            return jsonify({"error": "No face found in the image"}), 403
        #calculate cosine similarity
        similarity = cosine_similarity([embedding], [embedding_mean]).flatten()[0]
        print(f"similarity/confidence between embedding and mean from profile: {similarity}")
        if similarity > 0.6:
            user_doc.reference.update({
                "detection": False
            })
            print("User Face is detected, authorizing entry...")
            return jsonify({"message": "User detected"}), 200
        else:
            user_doc.reference.update({
                "detection": False
            })
            return jsonify({"message": "User not detected"}), 400
        
    else:
        return jsonify({"error": "Ticket is inactive. Try Again"}), 400
    

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)





