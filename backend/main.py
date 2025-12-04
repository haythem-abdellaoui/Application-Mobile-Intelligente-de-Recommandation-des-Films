from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from joblib import load

app = FastAPI()

genre_cluster_model = load("models/users_with_same_genres_preferences_cluster.pkl")
print(">>> RUNNING main.py <<<")

class UserGenres(BaseModel):
    user_id: str
    preferred_genres: list[int]

@app.post("/cluster")
def test_genre_cluster(user: UserGenres):
    g = user.preferred_genres
    if len(g) < 7:
        raise HTTPException(status_code=422, detail="preferred_genres must have at least 7 elements")
    try:
        merged_features = [
            g[2] | g[3],
            g[2] | g[4],
        ]
        cluster_label = genre_cluster_model.predict([merged_features])[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"user_id": user.user_id, "cluster": int(cluster_label)}
