import firebase_admin
from firebase_admin import credentials, firestore

<<<<<<< Updated upstream
cred = credentials.Certificate("fb_config.json")
=======
cred = credentials.Certificate("/Users/admin/Desktop/SWE Projects/Flutter Projects/Facial Recognition App/facial_recognition/backend/fb_config.json")
>>>>>>> Stashed changes
firebase_admin.initialize_app(cred)
db = firestore.client()