from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from joblib import load
from typing import List, Dict, Optional
import mysql.connector
from xgboost import XGBRegressor
import joblib
import pandas as pd
import time
import numpy as np
from xgboost import XGBClassifier


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
            int(g[2]) | int(g[3]),
            int(g[2]) | int(g[4]),
        ]
        cluster_label = int(genre_cluster_model.predict([merged_features])[0])

        # Connect to MySQL
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        # Fetch movies whose genres match the user's preferred genres
        # Here we just do a simple filter: movies containing any of the preferred genres
        preferred_genre_indices = [i for i, val in enumerate(g) if val == 1]
        genre_names = ['Comedy','Drama','Action','Sci-Fi','Thriller','Romance','Adventure','Crime']
        selected_genres = [genre_names[i] for i in preferred_genre_indices]

        genre_conditions = " OR ".join(["genres LIKE %s" for _ in selected_genres])
        sql = f"SELECT * FROM movies WHERE {genre_conditions} ORDER BY rating DESC LIMIT 10"

        cursor.execute(sql, [f"%{genre}%" for genre in selected_genres])
        recommended_movies = cursor.fetchall()

        cursor.close()
        conn.close()

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    return {
        "user_id": user.user_id,
        "cluster": cluster_label,
        "recommended_movies": recommended_movies
    }


# sending data to mysql

class Movie(BaseModel):
    id: str
    title: str
    genres: Optional[str] = None
    rating: Optional[float] = None
    year: Optional[int] = None
    description: Optional[str] = None
    posterUrl: Optional[str] = None

class User(BaseModel):
    userId: str
    username: str
    password: str
    gender: Optional[str] = None
    age: Optional[int] = None
    occupation: Optional[int] = None
    zipCode: Optional[str] = None
    preferred_genres: Optional[str] = None  

class DataPayload(BaseModel):
    movies: List[Movie]
    users: List[User]

# upload data to mysql
@app.post("/upload-sqlite-data")
def upload_sqlite_data(payload: DataPayload):
    try:
        # Connect to MySQL
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor()

        # Insert movies
        for movie in payload.movies:
            cursor.execute(
                """INSERT INTO movies (id, title, genres, rating, year, description, posterUrl)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)
                   ON DUPLICATE KEY UPDATE title=VALUES(title)""",
                (movie.id, movie.title, movie.genres, movie.rating, movie.year, movie.description, movie.posterUrl)
            )

        # Insert users
        for user in payload.users:
            cursor.execute(
                """INSERT INTO users (userId, username, password, gender, age, occupation, zipCode, preferred_genres)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                   ON DUPLICATE KEY UPDATE
                       username=VALUES(username),
                       password=VALUES(password),
                       gender=VALUES(gender),
                       age=VALUES(age),
                       occupation=VALUES(occupation),
                       zipCode=VALUES(zipCode),
                       preferred_genres=VALUES(preferred_genres)""",
                (
                    user.userId,
                    user.username,
                    user.password,
                    user.gender if user.gender is not None else None,
                    user.age if user.age is not None else None,
                    user.occupation if user.occupation is not None else None,
                    user.zipCode if user.zipCode is not None else None,
                    user.preferred_genres if user.preferred_genres is not None else None
                )
            )

        conn.commit()
        cursor.close()
        conn.close()

        return {
            "status": "success",
            "movies_inserted": len(payload.movies),
            "users_inserted": len(payload.users)
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# add user
@app.post("/add-user")
def add_user(user: User):
    # Generate userId if missing
    user_id = user.userId or str(int(time.time() * 1000))
    
    # Insert into MySQL
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="movies_mobile"
    )
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO users (userId, username, password, gender, age, occupation, zipCode, preferred_genres)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            username=VALUES(username),
            password=VALUES(password),
            gender=VALUES(gender),
            age=VALUES(age),
            occupation=VALUES(occupation),
            zipCode=VALUES(zipCode),
            preferred_genres=VALUES(preferred_genres)
        """,
        (
            user_id,
            user.username,
            user.password,
            user.gender,
            user.age,
            user.occupation,
            user.zipCode,
            user.preferred_genres
        )
    )
    conn.commit()
    cursor.close()
    conn.close()

    return {"status": "success", "userId": user_id}

class UserGenresUpdate(BaseModel):
    username: str
    preferred_genres: list[int]

@app.put("/update-user-genres")
def update_user_genres(payload: UserGenresUpdate):
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor()

        # Convert list of integers to comma-separated string
        genres_str = ','.join(map(str, payload.preferred_genres))
        print(f"🔹 Received payload: {payload.dict()}")
        print(f"🔹 Converted preferred_genres to string: {genres_str}")

        # Update by username
        cursor.execute(
            "UPDATE users SET preferred_genres = %s WHERE username = %s",
            (genres_str, payload.username)
        )
        conn.commit()

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail=f"No user found with username {payload.username}")

        cursor.close()
        conn.close()

        return {"status": "success", "username": payload.username}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class UsernameData(BaseModel):
    username: str

@app.post("/send-username")
async def receive_username(data: UsernameData):
    print("📥 Received username:", data.username)

    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        print("🔍 Fetching user from database...")

        cursor.execute(
            "SELECT userId, preferred_genres FROM users WHERE username = %s LIMIT 1",
            (data.username,)
        )
        user = cursor.fetchone()

        print("📌 User DB result:", user)

        if not user:
            print("❌ User not found")
            raise HTTPException(status_code=404, detail="User not found")

        g = list(map(int, user["preferred_genres"].split(",")))
        print("🎛 Preferred genres vector:", g)

        merged_features = [
            g[2] | g[3],
            g[2] | g[4],
        ]

        print("🧠 Cluster input features:", merged_features)

        cluster_label = int(genre_cluster_model.predict([merged_features])[0])

        print("🏷 Assigned cluster:", cluster_label)

        preferred_genre_indices = [i for i, val in enumerate(g) if val == 1]
        genre_names = ['Comedy','Drama','Action','Sci-Fi','Thriller','Romance','Adventure','Crime']
        selected_genres = [genre_names[i] for i in preferred_genre_indices]

        print("🎬 Selected genres for filtering:", selected_genres)

        genre_conditions = " OR ".join(["genres LIKE %s" for _ in selected_genres])
        sql = f"SELECT * FROM movies WHERE {genre_conditions} ORDER BY rating DESC LIMIT 10"

        print("🔎 SQL Query:", sql)

        cursor.execute(sql, [f"%{genre}%" for genre in selected_genres])
        recommended_movies = cursor.fetchall()

        print("🎥 Recommended movies:", recommended_movies)

        cursor.close()
        conn.close()

        return {
            "user_id": user["userId"],
            "cluster": cluster_label,
            "recommended_movies": recommended_movies
        }

    except Exception as e:
        print("🔥 ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))

xgb_model = joblib.load("models/xgb_predicting_future_movie_ratings_model.pkl")  # adjust path

class UserMovieRequest(BaseModel):
    user_id: str
    movie_id: str

@app.post("/compute_features")
def compute_features(req: UserMovieRequest):
    try:
        # Connect to MySQL
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        # Fetch all users
        cursor.execute("SELECT * FROM users")
        users = pd.DataFrame(cursor.fetchall())

        # Fetch all movies
        cursor.execute("SELECT * FROM movies")
        movies = pd.DataFrame(cursor.fetchall())

        # Check if user/movie exist
        if req.user_id not in users['userId'].values:
            raise HTTPException(status_code=404, detail="User not found")
        if req.movie_id not in movies['id'].values:
            raise HTTPException(status_code=404, detail="Movie not found")

        # User info
        user = users[users['userId'] == req.user_id].iloc[0]

        # For features needing user ratings, we only have movie ratings (global)
        user_avg_rating = movies['rating'].mean()
        user_std_rating = movies['rating'].std()

        # Movie info
        movie = movies[movies['id'] == req.movie_id].iloc[0]
        movie_std_rating = movies['rating'].std()
        movie_avg_viewer_age = users['age'].dropna().mean()  # average age across users
        movie_popularity = len(movies)

        # Occupation (convert to int if null)
        user_occupation = int(user['occupation']) if user['occupation'] is not None else 0

        # Average rating by occupation
        avg_rating_by_occupation = movies['rating'].mean()  # placeholder

        # Average rating by age
        avg_rating_by_age = movies['rating'].mean()  # placeholder

        # User-movie diff
        user_movie_avg_diff = user_avg_rating - movie['rating']

        # Cluster-based average rating (simplified)
        avg_rating_by_cluster = movies['rating'].mean()

        # Prepare feature vector for prediction
        feature_vector = [
            avg_rating_by_occupation,
            user_avg_rating,
            user_std_rating,
            avg_rating_by_age,
            user_movie_avg_diff,
            movie_std_rating,
            movie_avg_viewer_age,
            movie_popularity,
            user_occupation,
            avg_rating_by_cluster
        ]

        # Predict the rating using the model
        predicted_rating = float(xgb_model.predict([feature_vector])[0])

        features = {
            "avg_rating_by_occupation": avg_rating_by_occupation,
            "user_avg_rating": user_avg_rating,
            "user_std_rating": user_std_rating,
            "avg_rating_by_age": avg_rating_by_age,
            "user_movie_avg_diff": user_movie_avg_diff,
            "movie_std_rating": movie_std_rating,
            "movie_avg_viewer_age": movie_avg_viewer_age,
            "movie_popularity": movie_popularity,
            "Occupation": user_occupation,
            "avg_rating_by_cluster": avg_rating_by_cluster,
            "predicted_rating": predicted_rating
        }

        cursor.close()
        conn.close()

        print(f"🔹 Features & prediction for user {req.user_id} and movie {req.movie_id}: {features}")
        return {"user_id": req.user_id, "movie_id": req.movie_id, "features": features}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class PredictRequest(BaseModel):
    username: str

@app.post("/PredictFutureRating")
def predict_future_rating(req: PredictRequest):
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        # Get user info
        cursor.execute("SELECT userId, preferred_genres, age, occupation FROM users WHERE username = %s", (req.username,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")

        user_id = user_row['userId']
        user_age = user_row['age']
        user_occupation = int(user_row['occupation']) if user_row['occupation'] is not None else 0
        user_genres = list(map(int, user_row['preferred_genres'].split(",")))

        # Compute cluster from preferred genres
        merged_features = [
            user_genres[2] | user_genres[3],
            user_genres[2] | user_genres[4],
        ]
        cluster_label = int(genre_cluster_model.predict([merged_features])[0])

        # Fetch all movies
        cursor.execute("SELECT * FROM movies")
        movies = pd.DataFrame(cursor.fetchall())

        features_list = []
        for _, movie in movies.iterrows():
            # User-specific features (approximate since we don't have user ratings)
            user_avg_rating = movies['rating'].mean()
            user_std_rating = movies['rating'].std()

            # Movie-specific features
            movie_std_rating = movies['rating'].std()
            movie_avg_viewer_age = user_age if user_age else movies['rating'].mean()  # fallback
            movie_popularity = len(movies)

            # User-movie interaction
            genre_match = sum(user_genres[i] for i, g in enumerate(movie['genres'].split(',')) if i < len(user_genres))
            user_movie_avg_diff = user_avg_rating - movie['rating']

            # Occupation and cluster features
            avg_rating_by_occupation = movies['rating'].mean()
            avg_rating_by_cluster = movies['rating'].mean()

            features = [
                avg_rating_by_occupation,
                user_avg_rating,
                user_std_rating,
                movie_avg_viewer_age,
                user_movie_avg_diff,
                movie_std_rating,
                movie_popularity,
                user_occupation,
                cluster_label,
                genre_match
            ]
            features_list.append(features)

        X = np.array(features_list)
        predicted_ratings = xgb_model.predict(X)

        movies['predicted_rating'] = predicted_ratings
        top_movies = movies.sort_values(by='predicted_rating', ascending=False).head(10)
        recommended_movies = top_movies.to_dict(orient='records')

        print(f"🔹 Features & prediction for user {user_id}: {features_list[:1]} ...")
        print(f"🎥 Top recommended movies: {recommended_movies}")

        cursor.close()
        conn.close()

        return {
            "user_id": user_id,
            "username": req.username,
            "cluster": cluster_label,
            "recommended_movies": recommended_movies
        }

    except Exception as e:
        print("🔥 ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))


xgb_classifier = load("models/xgb_classifier_predicting_like_vs_dislike_model.pkl")

class UsernameData(BaseModel):
    username: str

@app.post("/PredictFutureRatingLikeVsDislike")
def predict_like_dislike(req: PredictRequest):
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        # Get user
        cursor.execute(
            "SELECT userId, age, occupation, preferred_genres FROM users WHERE username=%s",
            (req.username,)
        )
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")

        user_id = str(user_row["userId"])
        user_age = int(user_row["age"] or 25)
        user_occupation = int(user_row["occupation"] or 0)
        preferred_genres = list(map(int, (user_row.get("preferred_genres") or "0,0,0,0,0,0,0,0").split(",")))

        # Load movies
        cursor.execute("SELECT * FROM movies")
        movies = pd.DataFrame(cursor.fetchall())
        if movies.empty:
            return {"user_id": user_id, "recommended_movies": []}

        # Ensure numeric fields
        movies.fillna(0, inplace=True)

        # Compute features per movie
        features_list = []
        for _, movie in movies.iterrows():
            movie_genres = list(map(int, (movie.get("genres_vector") or "0,0,0,0,0,0,0,0").split(",")))
            genre_overlap = sum([u & m for u, m in zip(preferred_genres, movie_genres)])

            movie_year = int(movie.get("year") or 2000)
            movie_popularity = int(movie.get("popularity") or 1)  # fallback if you have popularity field

            # Features that vary per user and per movie
            features = [
                float(genre_overlap),                  # genre match
                float(user_age - movie_year),          # age-year diff
                float(user_occupation % 10),           # occupation encoded
                float(movie_popularity),               # popularity
                float(len([g for g in movie_genres if g == 1])),  # number of genres
                float(genre_overlap * movie_popularity),          # interaction feature
                float(movie_year),                     # movie year
                float(user_age),                        # user age
                float(sum(preferred_genres)),           # total preferred genres
                float(genre_overlap + user_occupation) # combined feature
            ]
            features_list.append(features)

        X = np.array(features_list, dtype=float)
        predicted_labels = xgb_classifier.predict(X)
        movies['predicted_label'] = np.where(np.isnan(predicted_labels), 0, predicted_labels).astype(int)

        liked_movies = movies[movies['predicted_label'] == 1]
        top_movies = liked_movies.head(10)

        recommended_movies = []
        for _, row in top_movies.iterrows():
            recommended_movies.append({
                "id": str(row.get("id", "")),
                "title": row.get("title", ""),
                "genres": row.get("genres", ""),
                "year": str(row.get("year", "")),
                "posterUrl": row.get("posterUrl", ""),
                "predicted_label": int(row.get("predicted_label", 0))
            })

        # Fallback: if no liked movies, return top 10 by any criteria
        if not recommended_movies:
            top_movies_fallback = movies.sample(10)  # random 10
            recommended_movies = []
            for _, row in top_movies_fallback.iterrows():
                recommended_movies.append({
                    "id": str(row.get("id", "")),
                    "title": row.get("title", ""),
                    "genres": row.get("genres", ""),
                    "year": str(row.get("year", "")),
                    "posterUrl": row.get("posterUrl", ""),
                    "predicted_label": int(row.get("predicted_label", 0))
                })

        cursor.close()
        conn.close()

        return {"user_id": user_id, "recommended_movies": recommended_movies}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))