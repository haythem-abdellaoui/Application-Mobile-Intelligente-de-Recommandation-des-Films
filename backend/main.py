from fastapi import FastAPI
import joblib
from pydantic import BaseModel
import numpy as np

app = FastAPI()

xgb_model_like_vs_dislike = joblib.load("models/xgb_classifier_predicting_like_vs_dislike_model.pkl")
kmeans_model_users_based_on_rating = joblib.load("models/kmeans_model_cluster_users_based_on_their_training.pkl")
xgb_model_predicting_future_movie_ratings = joblib.load("models/xgb_predicting_future_movie_ratings_model.pkl")
kmeans_model_users_based_on_genres = joblib.load("models/users_with_same_genres_preferences_cluster.pkl")

@app.get("/")
def read_root():
    return {"message": "API is running"}

# For rating polarity classifier
class LikeDislikeInput(BaseModel):
    features: list

@app.post("/predict-like-dislike")
def predict_like_dislike(data: LikeDislikeInput):
    arr = np.array(data.features).reshape(1, -1)
    pred = xgb_model_like_vs_dislike.predict(arr)
    return {"like_dislike": int(pred[0])}

# For predicting future ratings
class RatingInput(BaseModel):
    features: list

@app.post("/predict-rating")
def predict_rating(data: RatingInput):
    arr = np.array(data.features).reshape(1, -1)
    pred = xgb_model_predicting_future_movie_ratings.predict(arr)
    return {"predicted_rating": float(pred[0])}

# For clustering users based on ratings
class ClusterInput(BaseModel):
    features: list

@app.post("/cluster-user-ratings")
def cluster_user_ratings(data: ClusterInput):
    arr = np.array(data.features).reshape(1, -1)
    cluster = kmeans_model_users_based_on_rating.predict(arr)
    return {"cluster": int(cluster[0])}

# For clustering users based on genres
@app.post("/cluster-user-genres")
def cluster_user_genres(data: ClusterInput):
    arr = np.array(data.features).reshape(1, -1)
    cluster = kmeans_model_users_based_on_genres.predict(arr)
    return {"cluster": int(cluster[0])}
