from database import db, users_collection
from google.cloud import firestore

# Try to write directly
doc_ref = users_collection.document("direct_test")
doc_ref.set({
    "uid": "direct_test",
    "name": "Direct Write Test",
    "timestamp": firestore.SERVER_TIMESTAMP
})

print("Document written directly to Firestore")

# Read it back
doc = users_collection.document("direct_test").get()
if doc.exists:
    print(f"Found: {doc.to_dict()}")
else:
    print("Not found")
