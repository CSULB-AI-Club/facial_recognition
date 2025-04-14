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
import requests
import json
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# Initialize FaceAnalysis
app_face = FaceAnalysis()
app_face.prepare(ctx_id=0, det_size=(640, 640))


##### INSTITUTION MANAGEMENT FUNCTIONS #####

@app.route("/add_institution", methods=["POST"])
def add_institution():
    """Add a new institution to the database"""
    data = request.json
    
    if not data or "institution_name" not in data:
        return jsonify({"error": "Institution name is required"}), 400
    
    institution_id = str(uuid.uuid4())
    
    # Check if institution already exists
    existing_inst = db.collection("institutions").where("name", "==", data["institution_name"]).get()
    if existing_inst:
        return jsonify({"error": "Institution already exists"}), 400
    
    # Create institution in Firestore
    db.collection("institutions").document(institution_id).set({
        "institution_id": institution_id,
        "name": data["institution_name"],
        "description": data.get("description", ""),
        "auth_url": data.get("auth_url", ""),
        "api_key": data.get("api_key", ""),  # In production, use more secure storage
        "logo_url": data.get("logo_url", ""),
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
    
    return jsonify({
        "message": "Institution added successfully", 
        "institution_id": institution_id
    })


@app.route("/get_institutions", methods=["GET"])
def get_institutions():
    """Get all institutions"""
    institutions = db.collection("institutions").stream()
    
    institution_list = []
    for institution in institutions:
        inst_data = institution.to_dict()
        # Remove sensitive data
        if "api_key" in inst_data:
            del inst_data["api_key"]
        institution_list.append(inst_data)
    
    return jsonify({"institutions": institution_list})


##### USER-INSTITUTION LINKING FUNCTIONS #####

@app.route("/link_institution_account", methods=["POST"])
def link_institution_account():
    """Link a user account to an institution account"""
    data = request.json
    
    if not data or "user_id" not in data or "institution_id" not in data:
        return jsonify({"error": "User ID and Institution ID are required"}), 400
    
    user_id = data["user_id"]
    institution_id = data["institution_id"]
    
    # Verify user exists
    user = db.collection("users").document(user_id).get()
    if not user.exists:
        return jsonify({"error": "User not found"}), 404
    
    # Verify institution exists
    institution = db.collection("institutions").document(institution_id).get()
    if not institution.exists:
        return jsonify({"error": "Institution not found"}), 404
    
    # In a real app, this is where you'd verify credentials with the institution's API
    # For this mock implementation, we'll just create the link
    
    link_id = str(uuid.uuid4())
    
    # Store user-institution link
    db.collection("user_institutions").document(link_id).set({
        "link_id": link_id,
        "user_id": user_id,
        "institution_id": institution_id,
        "institution_username": data.get("institution_username", ""),
        "institution_user_id": data.get("institution_user_id", ""),
        # Don't store raw passwords! This is just for the mock
        "status": "active",
        "linked_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
    
    # Now call function to fetch initial tickets
    fetch_user_tickets(user_id, institution_id, link_id)
    
    return jsonify({
        "message": "Institution account linked successfully",
        "link_id": link_id
    })


@app.route("/get_user_institutions", methods=["GET"])
def get_user_institutions():
    """Get all institutions linked to a user"""
    user_id = request.args.get("user_id")
    
    if not user_id:
        return jsonify({"error": "User ID is required"}), 400
    
    # Get all institution links for this user
    links = db.collection("user_institutions").where("user_id", "==", user_id).stream()
    
    user_institutions = []
    for link in links:
        link_data = link.to_dict()
        # Get the institution details
        institution_id = link_data["institution_id"]
        institution = db.collection("institutions").document(institution_id).get().to_dict()
        
        # Remove sensitive information
        if "api_key" in institution:
            del institution["api_key"]
            
        user_institutions.append({
            "link_id": link_data["link_id"],
            "institution": institution,
            "status": link_data["status"],
            "linked_at": link_data["linked_at"]
        })
    
    return jsonify({"user_institutions": user_institutions})


##### TICKET MANAGEMENT FUNCTIONS #####

def fetch_user_tickets(user_id, institution_id, link_id):
    """Fetch tickets from an institution for a user"""
    # In a real app, this would call the institution's API
    # For this mock, we'll create some sample tickets
    
    # Get institution details
    institution = db.collection("institutions").document(institution_id).get().to_dict()
    institution_name = institution["name"]
    
    # Create mock tickets based on institution type
    mock_tickets = []
    current_date = datetime.now()
    
    if "Disney" in institution_name:
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Disney World - Park Hopper",
                "description": "Access to all Disney World parks",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=5)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Disney VIP Experience",
                "description": "Skip the lines with VIP access",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=2)).strftime("%Y-%m-%d"),
                "status": "active"
            }
        ]
    elif "Ticketmaster" in institution_name:
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Taylor Swift - The Eras Tour",
                "description": "Concert at SoFi Stadium",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=1)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "NBA Finals - Game 5",
                "description": "Lakers vs Celtics",
                "valid_from": (current_date + timedelta(days=10)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=10)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            }
        ]
    else:
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": f"{institution_name} General Admission",
                "description": "Standard entry ticket",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=30)).strftime("%Y-%m-%d"),
                "status": "active"
            }
        ]
    
    # Store the tickets in Firestore
    for ticket in mock_tickets:
        ticket_id = ticket["ticket_id"]
        db.collection("tickets").document(ticket_id).set({
            **ticket,
            "user_id": user_id,
            "institution_id": institution_id,
            "link_id": link_id,
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "accessed_count": 0,
            "last_accessed": None
        })
    
    return mock_tickets


@app.route("/get_user_tickets", methods=["GET"])
def get_user_tickets():
    """Get all tickets for a user"""
    user_id = request.args.get("user_id")
    
    if not user_id:
        return jsonify({"error": "User ID is required"}), 400
    
    # Get all tickets for this user
    tickets = db.collection("tickets").where("user_id", "==", user_id).stream()
    
    user_tickets = []
    for ticket in tickets:
        ticket_data = ticket.to_dict()
        
        # Get institution info
        institution_id = ticket_data["institution_id"]
        institution = db.collection("institutions").document(institution_id).get().to_dict()
        
        # Add institution name to ticket data
        ticket_data["institution_name"] = institution["name"]
        
        user_tickets.append(ticket_data)
    
    return jsonify({"tickets": user_tickets})


@app.route("/activate_ticket", methods=["POST"])
def activate_ticket():
    """Activate a ticket for facial recognition verification"""
    data = request.json
    
    if not data or "ticket_id" not in data or "user_id" not in data:
        return jsonify({"error": "Ticket ID and User ID are required"}), 400
    
    ticket_id = data["ticket_id"]
    user_id = data["user_id"]
    
    # Get the ticket
    ticket_ref = db.collection("tickets").document(ticket_id)
    ticket = ticket_ref.get()
    
    if not ticket.exists:
        return jsonify({"error": "Ticket not found"}), 404
    
    ticket_data = ticket.to_dict()
    
    # Check if ticket belongs to user
    if ticket_data["user_id"] != user_id:
        return jsonify({"error": "Ticket does not belong to this user"}), 403
    
    # Check if ticket is valid
    current_date = datetime.now().strftime("%Y-%m-%d")
    if ticket_data["valid_from"] > current_date or ticket_data["valid_until"] < current_date:
        return jsonify({"error": "Ticket is not valid at this time"}), 400
    
    # Activate the ticket for facial recognition
    user_ref = db.collection("users").document(user_id)
    user_ref.update({
        "detection": True,
        "active_ticket_id": ticket_id
    })
    
    # Update ticket accessed info
    ticket_ref.update({
        "accessed_count": ticket_data.get("accessed_count", 0) + 1,
        "last_accessed": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
    
    return jsonify({"message": "Ticket activated for facial recognition"})


##### EXISTING USER MANAGEMENT FUNCTIONS #####

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
            "detection": False,
            "active_ticket_id": None,
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
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
    users = db.collection("users").where("email", "==", email).where("password", "==", password).get()
    if not users:
        return jsonify({"error": "User not found"}), 404
    else:
        user_data = users[0].to_dict()
        return jsonify({
            "message": "User authenticated successfully",
            "user_id": user_data["user_id"],
            "first_name": user_data["first_name"],
            "last_name": user_data["last_name"]
        }), 200


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
    file_path = os.path.join("/Users/admin/Desktop/SWE Projects/Flutter Projects/Facial Recognition App/facial_recognition/backend/uploads", file.filename)  # the File Path shouldn't be hard coded
    file.save(file_path)
    
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
            # Get the active ticket ID
            active_ticket_id = user_data.get("active_ticket_id")
            
            # Mark ticket as used if there is one
            if active_ticket_id:
                # Here you could mark the ticket as "used" or update its status
                ticket_ref = db.collection("tickets").document(active_ticket_id)
                ticket_data = ticket_ref.get().to_dict()
                
                # Update the ticket data
                ticket_ref.update({
                    "last_verified": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    "verification_count": ticket_data.get("verification_count", 0) + 1
                })
            
            # Reset detection status
            user_doc.reference.update({
                "detection": False,
                "active_ticket_id": None
            })
            
            return jsonify({
                "message": "User detected and authenticated successfully",
                "ticket_verified": bool(active_ticket_id)
            }), 200
        else:
            return jsonify({"message": "User not detected"}), 400
        
    else:
        return jsonify({"error": "Ticket is inactive. Try Again"}), 400


##### INITIALIZE DATABASE WITH MOCK DATA #####

@app.route("/initialize_mock_data", methods=["POST"])
def initialize_mock_data():
    """Initialize the database with mock institutions"""
    # Default mock institutions
    mock_institutions = [
        {
            "name": "Disney Parks",
            "description": "Walt Disney World and Disneyland theme parks",
            "logo_url": "https://example.com/disney_logo.png",
            "auth_url": "https://api.disney.example.com/auth"
        },
        {
            "name": "Ticketmaster",
            "description": "Concerts, sports, and event tickets",
            "logo_url": "https://example.com/ticketmaster_logo.png",
            "auth_url": "https://api.ticketmaster.example.com/auth"
        },
        {
            "name": "Universal Studios",
            "description": "Universal theme parks and experiences",
            "logo_url": "https://example.com/universal_logo.png",
            "auth_url": "https://api.universal.example.com/auth"
        },
        {
            "name": "Six Flags",
            "description": "Six Flags theme parks",
            "logo_url": "https://example.com/sixflags_logo.png",
            "auth_url": "https://api.sixflags.example.com/auth"
        },
        {
            "name": "StubHub",
            "description": "Ticket reseller for sports and entertainment",
            "logo_url": "https://example.com/stubhub_logo.png",
            "auth_url": "https://api.stubhub.example.com/auth"
        }
    ]
    
    # Add each institution to Firestore
    for institution in mock_institutions:
        institution_id = str(uuid.uuid4())
        db.collection("institutions").document(institution_id).set({
            "institution_id": institution_id,
            "name": institution["name"],
            "description": institution["description"],
            "logo_url": institution["logo_url"],
            "auth_url": institution["auth_url"],
            "api_key": f"mock_api_key_{institution_id[:8]}",  # Mock API key
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return jsonify({"message": "Mock data initialized successfully"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)