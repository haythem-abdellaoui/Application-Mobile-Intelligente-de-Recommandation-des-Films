import requests
import json

url = "http://127.0.0.1:8000/cluster"
# User's code expects at least index 6 to exist (length 7+).
# Sample from user's code: [1,0,1,0,1,0,1,0] (length 8)
data = {
    "user_id": "test_user_123",
    "preferred_genres": [1, 0, 1, 0, 1, 0, 1, 0] 
}

try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
