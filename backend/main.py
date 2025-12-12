from fastapi import FastAPI, HTTPException, UploadFile, File
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
import pickle
import io
from fastapi import Body
import random
import hashlib

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



@app.post("/upload_ratings")
async def upload_ratings(file: UploadFile = File(...)):
    if not file.filename.endswith(".dat"):
        raise HTTPException(status_code=400, detail="Only .dat files allowed")

    content = await file.read()
    df = pd.read_csv(io.StringIO(content.decode()), sep="|", engine='python',
                     names=["UserID", "MovieID", "Rating", "Timestamp"])

    # Replace NaN with None for MySQL
    df = df.where(pd.notnull(df), None)

    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="movies_mobile"
    )
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ratings (
            UserID INT NOT NULL,
            MovieID INT NOT NULL,
            Rating FLOAT,
            Timestamp BIGINT,
            PRIMARY KEY (UserID, MovieID)
        )
    """)

    insert_query = """
        INSERT INTO ratings (UserID, MovieID, Rating, Timestamp)
        VALUES (%s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE Rating=VALUES(Rating), Timestamp=VALUES(Timestamp)
    """

    for row in df.itertuples(index=False):
        rating = row.Rating if pd.notna(row.Rating) else None
        timestamp = row.Timestamp if pd.notna(row.Timestamp) else None
        cursor.execute(insert_query, (row.UserID, row.MovieID, rating, timestamp))

    conn.commit()
    cursor.close()
    conn.close()

    return {"message": f"Inserted {len(df)} ratings successfully"}



kmeans_model = joblib.load("models/kmeans_model_cluster_users_based_on_their_training.pkl")

class PredictRequest(BaseModel):
    username: str

@app.post("/UserRatingsCluster")
def recommend_movies(req: PredictRequest):
    try:
        username = req.username
        if not username:
            raise HTTPException(status_code=400, detail="Username required")

        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="movies_mobile"
        )
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT UserID FROM users WHERE username=%s", (username,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")
        user_id = int(user_row["UserID"])

        cursor.execute("SELECT UserID, MovieID, Rating FROM ratings")
        ratings_df = pd.DataFrame(cursor.fetchall())
        if ratings_df.empty:
            # No ratings in system at all - return popular movies
            cursor.execute("SELECT * FROM movies ORDER BY RAND() LIMIT 10")
            movies = cursor.fetchall()
            recommended_movies = [{
                "id": int(row.get("id", 0)),
                "title": row.get("title", ""),
                "genres": row.get("genres", ""),
                "cluster": 0,
                "score": 0.0
            } for row in movies]
            cursor.close()
            conn.close()
            return {"user_id": user_id, "recommended_movies": recommended_movies}

        ratings_df = ratings_df.dropna(subset=["UserID", "MovieID", "Rating"])
        ratings_df["UserID"] = ratings_df["UserID"].astype(int)
        ratings_df["MovieID"] = ratings_df["MovieID"].astype(int)
        ratings_df["Rating"] = ratings_df["Rating"].astype(float)

        # Get user's ratings
        user_ratings = ratings_df[ratings_df["UserID"] == user_id].set_index("MovieID")["Rating"]

        # Calculate user statistics for clustering (only for users who have ratings)
        all_user_stats = ratings_df.groupby("UserID")["Rating"].agg(
            rating_count=lambda x: (x>0).sum(),
            rating_mean="mean",
            rating_std="std",
            high_rating_ratio=lambda x: (x>=4).sum() / (x>0).sum() if (x>0).sum()>0 else 0
        ).fillna(0)

        # Predict clusters for all users WHO HAVE RATINGS
        all_user_clusters = kmeans_model.predict(all_user_stats.values)
        all_user_stats['cluster'] = all_user_clusters
        
        # Determine user's cluster
        if user_id in all_user_stats.index:
            user_cluster = all_user_stats.loc[user_id]['cluster']
        else:
            # New user with no ratings - predict which cluster they'd belong to
            # Use overall average stats as placeholder
            avg_stats = all_user_stats.iloc[:, :-1].mean().values.reshape(1, -1)
            user_cluster = int(kmeans_model.predict(avg_stats)[0])

        # Get ALL users in the same cluster (not just those with ratings)
        cluster_users = all_user_stats[all_user_stats['cluster'] == user_cluster].index
        cluster_ratings = ratings_df[ratings_df["UserID"].isin(cluster_users)]

        # DEBUG: Print diagnostics
        print(f"\n=== DEBUG INFO FOR USER {user_id} ===")
        print(f"User cluster: {user_cluster}")
        print(f"Users in cluster: {len(cluster_users)}")
        print(f"User has rated {len(user_ratings)} movies")
        
        # Handle different scenarios
        if len(cluster_ratings) == 0:
            # No cluster data - return most popular movies overall
            print("No cluster data, returning popular movies")
            overall_popular = ratings_df.groupby("MovieID").agg({
                "Rating": ["mean", "count"]
            }).reset_index()
            overall_popular.columns = ["MovieID", "avg_rating", "rating_count"]
            overall_popular = overall_popular[overall_popular["rating_count"] >= 5]
            overall_popular["score"] = overall_popular["avg_rating"] * np.log1p(overall_popular["rating_count"])
            personalized_scores = dict(zip(overall_popular["MovieID"], overall_popular["score"]))
        elif user_ratings.empty or len(user_ratings) < 3:
            # New user or user with few ratings: use cluster averages with popularity boost
            print("Using cluster averages with popularity boost")
            cluster_movie_stats = cluster_ratings.groupby("MovieID").agg({
                "Rating": ["mean", "count"]
            }).reset_index()
            cluster_movie_stats.columns = ["MovieID", "avg_rating", "rating_count"]
            # Boost popular movies in cluster
            cluster_movie_stats["score"] = cluster_movie_stats["avg_rating"] * np.log1p(cluster_movie_stats["rating_count"])
            personalized_scores = dict(zip(cluster_movie_stats["MovieID"], cluster_movie_stats["score"]))
        else:
            # Existing user with enough ratings: Use collaborative filtering
            print("Using collaborative filtering")
            user_movies = set(user_ratings.index)
            
            # Calculate similarity with each user based on commonly rated movies
            user_similarities = {}
            for other_user in cluster_users:
                if other_user == user_id:
                    continue
                
                other_ratings = ratings_df[ratings_df["UserID"] == other_user].set_index("MovieID")["Rating"]
                
                # Find common movies
                common_movies = user_movies.intersection(set(other_ratings.index))
                
                if len(common_movies) >= 2:  # Need at least 2 common ratings
                    # Get ratings for common movies
                    user_common = user_ratings.loc[list(common_movies)]
                    other_common = other_ratings.loc[list(common_movies)]
                    
                    # Calculate Pearson correlation
                    correlation = user_common.corr(other_common)
                    
                    if not np.isnan(correlation) and correlation > 0:
                        user_similarities[other_user] = correlation
            
            print(f"Found {len(user_similarities)} similar users with correlation > 0")
            
            if len(user_similarities) == 0:
                # No similar users found, use cluster average with popularity
                cluster_movie_stats = cluster_ratings.groupby("MovieID").agg({
                    "Rating": ["mean", "count"]
                }).reset_index()
                cluster_movie_stats.columns = ["MovieID", "avg_rating", "rating_count"]
                cluster_movie_stats["score"] = cluster_movie_stats["avg_rating"] * np.log1p(cluster_movie_stats["rating_count"])
                personalized_scores = dict(zip(cluster_movie_stats["MovieID"], cluster_movie_stats["score"]))
                print("No similar users found, using cluster averages with popularity")
            else:
                # Get top 10 most similar users
                top_similar = sorted(user_similarities.items(), key=lambda x: x[1], reverse=True)[:10]
                similar_user_ids = [uid for uid, _ in top_similar]
                similar_weights = np.array([sim for _, sim in top_similar])
                
                # Normalize weights
                similar_weights = similar_weights / similar_weights.sum()
                
                print(f"Top similar user: {similar_user_ids[0]} with correlation {top_similar[0][1]:.3f}")
                
                # Get ratings from similar users
                similar_users_ratings = ratings_df[ratings_df["UserID"].isin(similar_user_ids)]
                
                # Calculate weighted average for each movie
                personalized_scores = {}
                for movie_id in similar_users_ratings["MovieID"].unique():
                    if movie_id in user_ratings.index:
                        continue  # Skip already rated
                    
                    # Get ratings from similar users for this movie
                    movie_ratings_df = similar_users_ratings[similar_users_ratings["MovieID"] == movie_id]
                    
                    weighted_sum = 0
                    weight_sum = 0
                    
                    for idx, (uid, weight) in enumerate(zip(similar_user_ids, similar_weights)):
                        user_rating = movie_ratings_df[movie_ratings_df["UserID"] == uid]["Rating"].values
                        if len(user_rating) > 0:
                            weighted_sum += user_rating[0] * weight
                            weight_sum += weight
                    
                    if weight_sum > 0:
                        personalized_scores[movie_id] = weighted_sum / weight_sum

        print(f"Generated {len(personalized_scores)} personalized scores")
        
        # Get all movies from database
        cursor.execute("SELECT * FROM movies")
        movies = pd.DataFrame(cursor.fetchall())

        if movies.empty:
            cursor.close()
            conn.close()
            return {"user_id": user_id, "recommended_movies": []}

        # Filter out already rated movies
        user_rated_movies = user_ratings.index.tolist()
        movies = movies[~movies['id'].isin(user_rated_movies)]

        # Apply personalized scores
        movies['score'] = movies['id'].map(personalized_scores).fillna(0)
        
        # Add some randomness to break ties and add variety
        # Hash user_id to get a valid seed (0 to 2^32-1)
        seed = hash(str(user_id)) % (2**32)
        np.random.seed(seed)
        movies['random_boost'] = np.random.uniform(0, 0.2, size=len(movies))
        movies['final_score'] = movies['score'] + movies['random_boost']

        # Sort by final score and get top 10
        top_movies = movies.sort_values(by='final_score', ascending=False).head(10)
        
        if len(top_movies) > 0:
            print(f"Top movie score: {top_movies.iloc[0]['score']:.3f}")
        print("=== END DEBUG ===\n")

        recommended_movies = [{
            "id": int(row.get("id", 0)),
            "title": row.get("title", ""),
            "genres": row.get("genres", ""),
            "cluster": int(user_cluster),
            "posterUrl": row.get("posterUrl", ""),
            "score": float(row.get("score", 0))
        } for _, row in top_movies.iterrows()]

        cursor.close()
        conn.close()
        
        return {"user_id": user_id, "recommended_movies": recommended_movies}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Recommendation
DATA_PATH = "models/data.pkl"
XGB_PATH = "models/xgb_model.pkl"
CLUSTER_SIM_PATH = "models/cluster_sim.pkl"
MOVIES_SIM_PATH = "models/movies_for_similarity.pkl"
SIM_MATRIX_PATH = "models/similarity_matrix.pkl"

data = pickle.load(open(DATA_PATH, "rb"))
xgb_model2 = pickle.load(open(XGB_PATH, "rb"))
cluster_sim = pickle.load(open(CLUSTER_SIM_PATH, "rb"))
movies_sim = pickle.load(open(MOVIES_SIM_PATH, "rb"))
similarity_matrix = pickle.load(open(SIM_MATRIX_PATH, "rb"))

class RatingRequest(BaseModel):
    username: str
    movie_id: int
    rating: float

def connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="movies_mobile"
    )

@app.post("/add-rating")
def add_rating(req: RatingRequest):
    try:
        conn = connect_db()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT userId FROM users WHERE username = %s", (req.username,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(status_code=404, detail="User not found")

        user_id = user_row["userId"]
        print(f"Debug: username='{req.username}', UserID={user_id}")  # debug message

        cursor.execute("SELECT id FROM movies WHERE id = %s", (req.movie_id,))
        print(f"Debug: movie_id={req.movie_id}")  # debug message
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Movie not found")

        cursor.execute("""
            INSERT INTO ratings (UserID, MovieID, Rating)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE Rating = VALUES(Rating)
        """, (user_id, req.movie_id, req.rating))

        conn.commit()
        cursor.close()
        conn.close()

        return {
            "message": "Rating added successfully",
            "UserID": user_id,
            "movieId": req.movie_id,
            "rating": req.rating
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/recommendations")
def get_personalized_recommendations(username: str, n: int = 15):
    db = connect_db()
    cursor = db.cursor(dictionary=True)

    cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
    profile = cursor.fetchone()
    if not profile:
        raise HTTPException(status_code=404, detail="Username not found")

    user_id = profile["userId"]
    print(f"Debug: username='{username}', UserID={user_id}")

    age = profile["age"] or 30
    gender_m = 1 if profile["gender"] == "M" else 0
    occupation = profile["occupation"] or 0
    preferred_genres_set = set((profile.get("preferred_genres") or "").split("|"))

    cursor.execute("SELECT MovieID, Rating FROM ratings WHERE UserID = %s", (user_id,))
    ratings = cursor.fetchall()
    rated_ids = {r["MovieID"] for r in ratings}
    total_ratings = len(ratings)
    avg_rating = np.mean([r["Rating"] for r in ratings]) if ratings else 3.0
    std_rating = np.std([r["Rating"] for r in ratings]) if ratings else 0.0
    user_cluster = 1 if avg_rating >= 4 else 0

    print(f"Debug: total_ratings={total_ratings}, avg_rating={avg_rating:.2f}, std_rating={std_rating:.2f}, cluster={user_cluster}")

    cursor.execute("SELECT * FROM movies")
    movies = cursor.fetchall()
    random.shuffle(movies)

    preds = []
    for movie in movies:
        if movie["id"] in rated_ids:
            continue

        genres_set = set(movie["genres"].split("|")) if movie["genres"] else set()
        genre_match = len(preferred_genres_set & genres_set)

        feat = np.array([
            age,
            gender_m,
            occupation,
            total_ratings,
            avg_rating,
            std_rating,
            movie["rating"] or 0,
            movie["year"] or 2000,
            len(genres_set) if genres_set else 1,
            1 if "Comedy" in genres_set else 0,
            1 if "Drama" in genres_set else 0,
            1 if "Action" in genres_set else 0,
            1 if "Sci-Fi" in genres_set else 0,
            1 if "Thriller" in genres_set else 0,
            1 if "Romance" in genres_set else 0,
            1 if "Adventure" in genres_set else 0,
            1 if "Crime" in genres_set else 0,
        ]).reshape(1, -1)

        prob = xgb_model2.predict_proba(feat)[0, 1]
        rating_boost = sum([0.1 for r in ratings if r["Rating"] >= 4])
        boost = 1.0 + 0.4 * cluster_sim[user_cluster].mean()
        score = (prob * boost + 0.3 * genre_match + rating_boost) * (1 + np.random.uniform(-0.03, 0.03))

        print(f"Debug: MovieID={movie['id']}, title='{movie['title']}', prob={prob:.3f}, genre_match={genre_match}, rating_boost={rating_boost:.2f}, boost={boost:.3f}, score={score:.3f}")

        preds.append({
            "id": movie["id"],
            "title": movie["title"],
            "genres": movie["genres"],
            "posterUrl": movie.get("posterUrl", ""),
            "cluster": user_cluster,
            "score": score
        })

    preds.sort(key=lambda x: x["score"], reverse=True)
    cursor.close()
    db.close()
    return {"recommended_movies": preds[:n]}

