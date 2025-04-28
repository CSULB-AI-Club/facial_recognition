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
from datetime import datetime, timedelta


app = Flask(__name__)
CORS(app)

#Initialize FaceAnalysis
app_face = FaceAnalysis()
app_face.prepare(ctx_id=0, det_size=(640, 640))
############# NEW FUNCTIONS (Added by Shaun ) ###########

# Set up paths for storing logos
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static', 'logos')
# Make sure the directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


##### INSTITUTION MANAGEMENT FUNCTIONS ###############

@app.route("/add_institution", methods=["POST"]) 
def add_institution():
    """Add a new institution to the database with custom login requirements"""
    data = request.json
    
    if not data or "institution_name" not in data:
        return jsonify({"error": "Institution name is required"}), 400
    
    # Validate if login_requirements is provided and properly formatted
    if "login_requirements" not in data or not isinstance(data["login_requirements"], list):
        return jsonify({"error": "Login requirements must be provided as a list of field objects"}), 400
    
    # Validate each login requirement field has the required properties
    for field in data["login_requirements"]:
        if "field_name" not in field or "field_type" not in field or "required" not in field:
            return jsonify({"error": "Each login requirement field must have field_name, field_type, and required properties"}), 400
    
    institution_id = str(uuid.uuid4())

    # Check if institution already exists
    existing_inst = db.collection("institutions").where("name", "==", data["institution_name"]).get()
    if existing_inst:
        return jsonify({"error": "Institution already exists"}), 400
    
    # Create institution in Firestore with login requirements
    db.collection("institutions").document(institution_id).set({
        "institution_id": institution_id,
        "name": data["institution_name"],
        "description": data.get("description", ""),
        "logo_url": data.get("logo_url", ""),
        "auth_url": data.get("auth_url", ""),
        "api_key": data.get("api_key", f"mock_api_key_{institution_id[:8]}"),
        "login_requirements": data["login_requirements"],
        "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
    
    return jsonify({
        "message": "Institution added successfully", 
        "institution_id": institution_id
    })

# DEV NOTE (KEITH) : this function isn't necessary, there is firebase package that can manage these kinds of task in the frontend.

@app.route("/get_institutions", methods=["GET"])
def get_institutions():
    """Get all institutions"""
    institutions = db.collection("institutions").stream()

    institution_list = []
    for institution in institutions:
        inst_data = institution.to_dict()
        institution_list.append(inst_data)

    return jsonify({"institutions": institution_list})


##### USER-iNSTITUTION LINKING FUNCTIONS #####

@app.route("/link_institution_account", methods=["POST"])
def link_institution_account():
    """Link a user account to an institution account with custom required fields"""
    data = request.json

    if not data or "uid" not in data or "institution_id" not in data:
        return jsonify({"error": "User ID and Institution ID are required"}), 400
    
    user_id = data["uid"]
    inst_id = data["institution_id"]
    credentials = data.get("credentials", {})

    # Verify if user exists
    user = db.collection("users").document(user_id).get()
    if not user.exists:
        return jsonify({"error": "User not found"}), 404
    
    # Verify if institution exists
    inst = db.collection("institutions").document(inst_id).get()
    if not inst.exists:
        return jsonify({"error": "Institution not found"}), 404
    
    # Get institution details including login requirements
    institution_data = inst.to_dict()
    login_requirements = institution_data.get("login_requirements", [])
    
    # Validate that all required credentials are provided
    missing_fields = []
    for field in login_requirements:
        if field.get("required", False) and field["field_label"] not in credentials:
            missing_fields.append(field["field_label"])
    
    if missing_fields:
        return jsonify({
            "error": f"Missing required credentials: {', '.join(missing_fields)}"
        }), 400

    # In a real app, this is where we'd verify credentials with the institution's API
    # For this mock implementation, we'll just create the link
    # this unique ID will be for the document ID, so everything is unique, but tied to each other by user_id
    link_id = str(uuid.uuid4())

    # Store user-institution link with the provided credentials
    db.collection("user_institutions").document(link_id).set({
        "link_id": link_id,
        "user_id": user_id,
        "institution_id": inst_id,
        "institution_name": data["institution_name"],
        "credentials": credentials,  # Store all provided credentials
        "status": "active",
        "linked_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S") 
    })

    # Call function to fetch tickets that the user has
    fetch_user_tickets(user_id, inst_id, link_id)

    return jsonify({
        "message": "Institution account linked successfully",
        "link_id": link_id
    })

# EDITOR NOTE (KEITH) : this function is also unnecessary 
@app.route("/get_user_institutions", methods=["POST"])
def get_user_institutions():
    """Get all institutions linked to a user"""
    user_id = request.args.get("user_id")

    if not user_id:
        return jsonify({"error": "User ID required"}), 400
    
    # Get all institutions links for this user
    links = db.collection("user_institutions").where("user_id", "==", user_id).stream()

    user_institutions = []
    for link in links:
        link_data = link.to_dict()
        #Get the inst details
        inst_id = link_data["institution_id"]
        institution = db.collection("institutions").document(inst_id).get().to_dict()

        # HERE is where we would remove any sensitive information
        # e.g. institution api_key

        user_institutions.append({
            "link_id": link_data["link_id"],
            "institution": institution,
            "status": link_data["status"],
            "linked_at": link_data["linked_atj"]
        })

    return jsonify({"user_institutions": user_institutions})


##### TICKET MANAGEMENT FUNCTIONS #####
def fetch_user_tickets(user_id, institution_id, link_id):
    """Fetch tickets from an institution for a user"""
    # In a real app, this would call the institution's API
    # For this mock, we'll create sample tickets based on institution type

    # Get institution details
    institution = db.collection("institutions").document(institution_id).get().to_dict()
    institution_name = institution["name"]
    
    # Create mock tickets based on institution type
    mock_tickets = []
    current_date = datetime.now()
    
    if institution_name == "Disney Parks":
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
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Epcot After Hours",
                "description": "Special evening access to Epcot attractions",
                "valid_from": (current_date + timedelta(days=3)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=3)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            }
        ]
    elif institution_name == "Ticketmaster":
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Taylor Swift - The Eras Tour",
                "description": "Concert at SoFi Stadium, Row A, Seat 15",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=1)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "NBA Finals - Game 5",
                "description": "Lakers vs Celtics, Section 112, Row 7, Seat 8",
                "valid_from": (current_date + timedelta(days=10)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=10)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Broadway: Hamilton",
                "description": "Orchestra Center, Row F, Seat 107",
                "valid_from": (current_date - timedelta(days=5)).strftime("%Y-%m-%d"),
                "valid_until": (current_date - timedelta(days=5)).strftime("%Y-%m-%d"),
                "status": "expired"
            }
        ]
    elif institution_name == "Universal Studios":
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Universal 2-Day Pass",
                "description": "Access to Universal Studios and Islands of Adventure",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=2)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Universal Express Pass",
                "description": "Skip regular lines at participating attractions",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=1)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Halloween Horror Nights",
                "description": "Special event access - October 31st",
                "valid_from": (current_date + timedelta(days=45)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=45)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            }
        ]
    elif institution_name == "Six Flags":
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Six Flags Gold Season Pass",
                "description": "Unlimited visits to all Six Flags parks",
                "valid_from": (current_date - timedelta(days=30)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=335)).strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Flash Pass",
                "description": "Priority access to selected rides",
                "valid_from": (current_date + timedelta(days=5)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=5)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            }
        ]
    elif institution_name == "StubHub":
        mock_tickets = [
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Coldplay World Tour",
                "description": "Rose Bowl Stadium, Section 7, Row 20, Seats 5-6",
                "valid_from": (current_date + timedelta(days=15)).strftime("%Y-%m-%d"),
                "valid_until": (current_date + timedelta(days=15)).strftime("%Y-%m-%d"),
                "status": "upcoming"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "LA Dodgers vs SF Giants",
                "description": "Dodger Stadium, Loge Level, Section 103, Row C, Seat 5",
                "valid_from": current_date.strftime("%Y-%m-%d"),
                "valid_until": current_date.strftime("%Y-%m-%d"),
                "status": "active"
            },
            {
                "ticket_id": str(uuid.uuid4()),
                "name": "Coachella Music Festival - Weekend 1",
                "description": "General Admission with Shuttle Pass",
                "valid_from": (current_date - timedelta(days=45)).strftime("%Y-%m-%d"),
                "valid_until": (current_date - timedelta(days=43)).strftime("%Y-%m-%d"),
                "status": "expired"
            }
        ]
    else:
        # Default tickets for any other institution
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
    tickets = db.collection("tickets").where("user_id", "==", user_id).get().stream()

    user_tickets = []
    for ticket in tickets:
        ticket_data = ticket.to_dict()

        #Get institution info
        inst_id = ticket_data["institution_id"]
        institution = db.collection("institutions").document(inst_id).get().to_dict()

        # Add institution name to ticket data
        ticket_data["institution_name"] = institution["name"]

        user_tickets.append(ticket_data)

    return jsonify({"tickets": user_tickets})

@app.route("/activate_ticket", methods=["POST"])
def activate_ticket():
    data = request.json
    if not data or "ticket_id" not in data or "user_id" not in data:
        return jsonify({"error": "Ticket ID and User ID are required"}), 400

    ticket_id = data["ticket_id"]
    user_id = data["user_id"]

    # Get the ticket
    ticket_ref = db.collection("tickets").document(ticket_id)
    ticket = ticket_ref.get()

    if not ticket.exists:
        return jsonify({"error": "Ticket not found"}), 400
    
    ticket_data = ticket.to_dict()

    # Chheck if ticket belongs to user
    if ticket_data["user_id"] != user_id:
        return jsonify({"error": "Ticket does not belong to this user"}), 403
    
    # Check if this ticket is valid
    current_date = datetime.now().strftime("%Y-%m-%d")
    if ticket_data["valid_from"] > current_date or ticket_data["valid_until"] < current_date:
        return jsonify({"error": "Ticket is not valid at this time"}), 400
    
    # Activate the ticket for facial recognition
    users_ref = db.collection("users").document(user_id)
    users_ref.update({
        "detection": True,
        "active_ticket_id": ticket_id
    })

    # Update ticket accessed info
    ticket_ref.update({
        "accessed_count": ticket_data.get("accessed_count", 0) + 1,
        "last_accessed": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

    return jsonify({"message": "Ticket activated for facial recognition"})


##### INTIALIZE THE DATABASE WITH MOCK DATA #######

@app.route('/static/logos/<path:filename>')
def serve_logo(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@app.route("/initialize_mock_data", methods=["POST"])
def initialize_mock_data():
    """Initialize the database with mock institutions including login requirements"""
    # Create a mapping of institution names to logo filenames
    # Assuming you've downloaded these files and placed them in your UPLOAD_FOLDER
    logo_mapping = {
        "Disney Parks": "disney_logo.png",
        "Ticketmaster": "ticketmaster_logo.png",
        "Universal Studios": "universal_logo.png",
        "Six Flags": "sixflags_logo.png",
        "StubHub": "stubhub_logo.png"
    }
    
    # Base URL for accessing logos
    base_url = request.host_url.rstrip('/') + '/static/logos/'
    
    # Default mock institutions with login requirements
    mock_institutions = [
        {
            "name": "Disney Parks",
            "description": "Walt Disney World and Disneyland theme parks",
            "auth_url": "https://api.disney.example.com/auth",
            "login_requirements": [
                {
                    "field_name": "email",
                    "field_type": "email",
                    "field_label": "Email Address",
                    "required": True,
                    "placeholder": "your.email@example.com"
                },
                {
                    "field_name": "password",
                    "field_type": "password",
                    "field_label": "Password",
                    "required": True,
                    "placeholder": "Your Disney password"
                },
                {
                    "field_name": "member_id",
                    "field_type": "text",
                    "field_label": "Disney Member ID",
                    "required": False,
                    "placeholder": "Optional: Enter your Member ID if available"
                }
            ]
        },
        {
            "name": "Ticketmaster",
            "description": "Concerts, sports, and event tickets",
            "auth_url": "https://api.ticketmaster.example.com/auth",
            "login_requirements": [
                {
                    "field_name": "username",
                    "field_type": "text",
                    "field_label": "Username",
                    "required": True,
                    "placeholder": "Your Ticketmaster username"
                },
                {
                    "field_name": "password",
                    "field_type": "password",
                    "field_label": "Password",
                    "required": True,
                    "placeholder": "Your Ticketmaster password"
                }
            ]
        },
        {
            "name": "Universal Studios",
            "description": "Universal theme parks and experiences",
            "auth_url": "https://api.universal.example.com/auth",
            "login_requirements": [
                {
                    "field_name": "email",
                    "field_type": "email",
                    "field_label": "Email Address",
                    "required": True,
                    "placeholder": "your.email@example.com"
                },
                {
                    "field_name": "password",
                    "field_type": "password",
                    "field_label": "Password",
                    "required": True,
                    "placeholder": "Your Universal password"
                },
                {
                    "field_name": "annual_pass_number",
                    "field_type": "text",
                    "field_label": "Annual Pass Number",
                    "required": False,
                    "placeholder": "If you have an annual pass"
                }
            ]
        },
        {
            "name": "Six Flags",
            "description": "Six Flags theme parks",
            "auth_url": "https://api.sixflags.example.com/auth",
            "login_requirements": [
                {
                    "field_name": "member_number",
                    "field_type": "text",
                    "field_label": "Member Number",
                    "required": True,
                    "placeholder": "Your Six Flags member number"
                },
                {
                    "field_name": "zipcode",
                    "field_type": "text",
                    "field_label": "Billing ZIP Code",
                    "required": True,
                    "placeholder": "Billing ZIP code"
                }
            ]
        },
        {
            "name": "StubHub",
            "description": "Ticket reseller for sports and entertainment",
            "auth_url": "https://api.stubhub.example.com/auth",
            "login_requirements": [
                {
                    "field_name": "email",
                    "field_type": "email",
                    "field_label": "Email Address",
                    "required": True,
                    "placeholder": "your.email@example.com"
                },
                {
                    "field_name": "password",
                    "field_type": "password",
                    "field_label": "Password",
                    "required": True,
                    "placeholder": "Your StubHub password"
                },
                {
                    "field_name": "phone",
                    "field_type": "tel",
                    "field_label": "Phone Number",
                    "required": False,
                    "placeholder": "For verification purposes"
                }
            ]
        }
    ]
    
    # Add each institution to Firestore
    for institution in mock_institutions:
        institution_id = str(uuid.uuid4())
        
        # Get the logo filename for this institution
        logo_filename = logo_mapping.get(institution["name"])
        logo_url = base_url + logo_filename if logo_filename else ""
        
        db.collection("institutions").document(institution_id).set({
            "institution_id": institution_id,
            "name": institution["name"],
            "description": institution["description"],
            "logo_url": logo_url,
            "auth_url": institution["auth_url"],
            "api_key": f"mock_api_key_{institution_id[:8]}",  # Mock API key
            "login_requirements": institution["login_requirements"],
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    
    return jsonify({"message": "Mock data initialized successfully"})



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


#For Institution Login Page
@app.route("/institution_login", methods=["POST"])
def institution_login():
    """Login for institutions"""
    data = request.json

    if not data or "email" not in data or "password" not in data:
        return jsonify({"error": "Email and password are required"}), 400

    email = data["email"]
    password = data["password"]

    institution_query = db.collection("institutions").where("email", "==", email).get()

    if not institution_query:
        return jsonify({"error": "Invalid email or password"}), 401

    institution = institution_query[0].to_dict()

    if institution.get("password") != password:
        return jsonify({"error": "Invalid email or password"}), 401

    return jsonify({
        "message": "Login successful",
        "institution_id": institution.get("institution_id"),
        "institution_name": institution.get("name")
    })

# Gets all tickets with status upcoming or active (for home page)
@app.route("/get_home_tickets", methods=["POST"])
def get_institution_tickets():
    """Get all tickets linked to an institution"""
    data = request.json

    if not data or "institution_id" not in data:
        return jsonify({"error": "Institution ID is required"}), 400

    institution_id = data["institution_id"]

    tickets_query = db.collection("tickets").where("institution_id", "==", institution_id).stream()
    
    tickets = []
    for ticket in tickets_query:
        ticket_data = ticket.to_dict()
        if ticket_data.get("status") in ["active", "upcoming"]:
            tickets.append({
                "ticket_id": ticket_data.get("ticket_id"),
                "name": ticket_data.get("name"),
                "description": ticket_data.get("description"),
                "institution_id": ticket_data.get("institution_id"),
                "user_id": ticket_data.get("user_id"),
                "link_id": ticket_data.get("link_id"),
                "status": ticket_data.get("status"),
                "created_at": ticket_data.get("created_at"),
                "last_accessed": ticket_data.get("last_accessed"),
                "accessed_count": ticket_data.get("accessed_count"),
                "valid_from": ticket_data.get("valid_from"),
                "valid_until": ticket_data.get("valid_until"),
            })

    return jsonify({"tickets": tickets})

# Gets all used tickets (for seperate page)
@app.route("/get_used_tickets", methods=["POST"])
def get_used_tickets():
    """Get all tickets linked to an institution"""
    data = request.json

    if not data or "institution_id" not in data:
        return jsonify({"error": "Institution ID is required"}), 400

    institution_id = data["institution_id"]

    tickets_query = db.collection("tickets").where("institution_id", "==", institution_id).stream()

    tickets = []
    for ticket in tickets_query:
        ticket_data = ticket.to_dict()
        if ticket_data.get("status") == "used":
            tickets.append({
                "ticket_id": ticket_data.get("ticket_id"),
                "name": ticket_data.get("name"),
                "description": ticket_data.get("description"),
                "institution_id": ticket_data.get("institution_id"),
                "user_id": ticket_data.get("user_id"),
                "link_id": ticket_data.get("link_id"),
                "status": ticket_data.get("status"),
                "created_at": ticket_data.get("created_at"),
                "last_accessed": ticket_data.get("last_accessed"),
                "accessed_count": ticket_data.get("accessed_count"),
                "valid_from": ticket_data.get("valid_from"),
                "valid_until": ticket_data.get("valid_until"),
            })

    return jsonify({"tickets": tickets})

# changes an active ticket to a used ticket
def use_ticket(ticket_id):
    """Mark an active ticket as used"""
    print("Marking ticket as used...")
    ticket_ref = db.collection("tickets").document(ticket_id)
    ticket = ticket_ref.get()

    if not ticket.exists:
        return jsonify({"error": "Ticket not found"}), 404

    ticket_data = ticket.to_dict()

    if ticket_data.get("status") != "Active":
        return jsonify({"error": "Ticket is not active"}), 400

    # Update the status to "used"
    ticket_ref.update({
        "status": "used",
        "last_accessed": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "accessed_count": ticket_data.get("accessed_count", 0) + 1
    })

    return jsonify({"message": "Ticket marked as used"})


#### THIS BOTTOM PORTION IS FOR FACE MATCHING ####
# So when the user blinks, it sends the image to this endpoint
import os
from werkzeug.utils import secure_filename

# where we’ll temporarily store incoming photos for matching
IMAGE_UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
os.makedirs(IMAGE_UPLOAD_FOLDER, exist_ok=True)

@app.route("/match_face", methods=["POST"])
def match_face():
    """
    Given an image and institution_id, 
    find any 'active' ticket-holder whose stored face embeddings
    match the submitted photo within a cosine‐similarity threshold.
    """
    # 1) Validate inputs
    if 'image' not in request.files or 'institution_id' not in request.form:
        return jsonify({"error": "Both 'image' file and 'institution_id' are required"}), 400

    img_file = request.files['image']
    inst_id = request.form['institution_id']
 
    # Change this as needed
    threshold = 0.1

    # 2) Save incoming image to disk
    filename = secure_filename(img_file.filename)
    file_path = os.path.join(IMAGE_UPLOAD_FOLDER, filename)
    img_file.save(file_path)

    # 3) Compute embedding of the submitted photo
    query_emb = np.array(get_embeddings(file_path))
    if query_emb is None:
        return jsonify({"error": "No face detected in submitted image"}), 400

    # 4) Fetch all 'active' tickets for this institution
    tickets = list(db.collection("tickets") \
                .where("institution_id", "==", inst_id) \
                .where("status", "==", "Active") \
                .stream())
    user_ids = {t.to_dict().get("user_id") for t in tickets}

    if not user_ids:
        return jsonify({"error": "No active tickets found for this institution"}), 404

    # 5) Load each user’s stored embeddings
    user_matches = {}
    for uid in user_ids:
        udoc = db.collection("users").document(uid).get()
        if not udoc.exists:
            continue
        udata = udoc.to_dict()
        # collect all keys like 'Embedding0', 'Embedding1', …
        embeddings = [
            np.array(udata[k]) for k in udata.keys() if k.startswith("Embedding")
        ]
        if embeddings:
            user_matches[uid] = np.mean(embeddings, axis=0)

    if not user_matches:
        return jsonify({"error": "No stored embeddings for any active-ticket users"}), 404

    # 6) Compute cosine-similarities
    best_uid, best_score = None, 0.0
    for uid, embs in user_matches.items():
        sims = cosine_similarity([query_emb], [embs]).flatten()[0]
        top = float(np.max(sims))
        if top > best_score:
            best_score, best_uid = top, uid
        print(f"User ID: {uid}, Similarity: {sims}") 
    
    
    print(f"Best Score: {best_score}")
    # 7) Check threshold and respond
    if best_score >= threshold:
        user = db.collection("users").where("user_id", "==", uid).get()
        user_doc = user[0]
        user_data = user_doc.to_dict()
        user_info = {
            "user_id": best_uid,
            "first_name": user_data["first_name"],
            "last_name":  user_data["last_name"],
            "email":      user_data["email"]
        }
        ticket_id = str([t.to_dict().get("ticket_id") for t in tickets if t.to_dict().get("user_id") == best_uid][0])
        print(ticket_id)
        use_ticket(ticket_id)
        return jsonify({
            "message": f"Match found: {user_info['first_name']} {user_info['last_name']}",
            "similarity": best_score,
            "user": user_info
        }), 200
    else:
        return jsonify({
            "message": "Could not match face to any active tickets"
        }), 404





if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)





