import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("/Facial Recognition App/facial_recognition/backend/fb_config.json")
firebase_admin.initialize_app(cred)
db = firestore.client()