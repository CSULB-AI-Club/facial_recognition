



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
@app.route("/use_ticket", methods=["POST"])
def use_ticket():
    """Mark an active ticket as used"""
    data = request.json

    if not data or "ticket_id" not in data:
        return jsonify({"error": "Ticket ID is required"}), 400

    ticket_id = data["ticket_id"]

    ticket_ref = db.collection("tickets").document(ticket_id)
    ticket = ticket_ref.get()

    if not ticket.exists:
        return jsonify({"error": "Ticket not found"}), 404

    ticket_data = ticket.to_dict()

    if ticket_data.get("status") != "active":
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
    threshold = 0.6

    # 2) Save incoming image to disk
    filename = secure_filename(img_file.filename)
    file_path = os.path.join(IMAGE_UPLOAD_FOLDER, filename)
    img_file.save(file_path)

    # 3) Compute embedding of the submitted photo
    query_emb = get_embeddings(file_path)
    if query_emb is None:
        return jsonify({"error": "No face detected in submitted image"}), 400

    # 4) Fetch all 'active' tickets for this institution
    tickets = db.collection("tickets") \
                .where("institution_id", "==", inst_id) \
                .where("status", "==", "active") \
                .stream()
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
            np.array(udata[k]) 
            for k in udata.keys() 
            if k.startswith("Embedding")
        ]
        if embeddings:
            user_matches[uid] = embeddings

    if not user_matches:
        return jsonify({"error": "No stored embeddings for any active-ticket users"}), 404

    # 6) Compute cosine-similarities
    best_uid, best_score = None, 0.0
    for uid, embs in user_matches.items():
        sims = cosine_similarity([query_emb], embs).flatten()
        top = float(np.max(sims))
        if top > best_score:
            best_score, best_uid = top, uid

    # 7) Check threshold and respond
    if best_score >= threshold:
        user_doc = db.collection("users").document(best_uid).get().to_dict()
        user_info = {
            "user_id": best_uid,
            "first_name": user_doc.get("first_name"),
            "last_name":  user_doc.get("last_name"),
            "email":      user_doc.get("email")
        }
        return jsonify({
            "message": f"Match found: {user_info['first_name']} {user_info['last_name']}",
            "similarity": best_score,
            "user": user_info
        }), 200
    else:
        return jsonify({
            "message": "Could not match face to any active tickets"
        }), 404
