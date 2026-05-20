import firebase_admin
from firebase_admin import credentials, firestore

if not firebase_admin._apps:
    cred = credentials.Certificate("service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

users_collection = db.collection("Users")
products_collection = db.collection("products")
orders_collection = db.collection("orders")